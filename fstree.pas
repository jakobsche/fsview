unit FSTree;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

  TFileSystemNode = class;

  { TFileSystem }

  TFileSystem = class(TComponent)
  private
    FRoot: TFileSystemNode;
    class function GetNodeSeparator: string;
    function GetRoot: TFileSystemNode;
  public
    function FindNodeByFileName(AFileName: string): TFileSystemNode; overload;
    function FindNodeByFileName(CurrentNode: TFileSystemNode; AFileName: string):
      TFileSystemNode; overload;
    property NodeSeparator: string read GetNodeSeparator;
    property Root: TFileSystemNode read GetRoot;
  end;

  { TFileSystemNode }

  TFileSystemNode = class(TComponent)
  private
    FFirstChild, FNext, FParent: TFileSystemNode;
    FSearchRecord: TSearchRec;
    function GetFileName: string;
    function GetFirstChild: TFileSystemNode;
    function GetNext: TFileSystemNode;
    function GetNodeName: string;
    function GetPrevious: TFileSystemNode;
    function GetRoot: TFileSystemNode;
    procedure SetPrevious(AValue: TFileSystemNode);
    procedure SetRoot(AValue: TFileSystemNode);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;
  public
    constructor Create(AFileSystem: TFileSystem; ANodeName: string); virtual;
    constructor Create(AFileSystem: TFileSystem; AParent: TFileSystemNode; ASearchRec: TSearchRec); virtual;
    destructor Destroy; override;
    function IsDirectory: Boolean;
    function IsValid: Boolean;
    property FileName: string read GetFileName;
    property FirstChild: TFileSystemNode read GetFirstChild;
    property Next: TFileSystemNode read GetNext;
    property NodeName: string read GetNodeName;
    property Parent: TFileSystemNode read FParent;
    property Previous: TFileSystemNode read GetPrevious write SetPrevious;
    property Root: TFileSystemNode read GetRoot write SetRoot;
  end;

implementation

uses Patch, Op;

{ TFileSystem }

function TFileSystem.GetRoot: TFileSystemNode;
begin
  if FRoot = nil then begin
    FRoot := TFileSystemNode.Create(Self, NodeSeparator);
  end;
  Result := FRoot;
end;

function TFileSystem.FindNodeByFileName(AFileName: string): TFileSystemNode;
var
  Right, NN: string;
begin
  NN := Parse(AFileName, NodeSeparator, Right);
  if NN = '' then begin
    Result := Root;
    if Right <> '' then Result := FindNodeByFileName(Root, Right)
  end
  else Exception.CreateFmt('"%s" is an invalid filename.', [AFileName]);
end;

function TFileSystem.FindNodeByFileName(CurrentNode: TFileSystemNode;
  AFileName: string): TFileSystemNode;
var
  NN, Right: string;
begin
  NN := Parse(AFileName, NodeSeparator, Right);
  while Right <> '' do {... Was fehlt hier?};
  Result := CurrentNode.FirstChild;
  while NN <> '' do
    while Result <> nil do
      if Result.NodeName = NN then begin
        NN := Parse(Right, NodeSeparator, Right);
        if NN <> '' then begin
          Result := Result.FirstChild;
          Break
        end;
      end
      else Result := Result.Next;
end;

{ TFileSystemNode }

function TFileSystemNode.GetFileName: string;
begin
  Result := NodeName;
  if Parent <> nil then Result := BuildFileName(Parent.FileName, Result)
end;

function TFileSystemNode.GetFirstChild: TFileSystemNode;
var
  R: Longint;
  SR: TSearchRec;
begin
  Result := nil;
  if Assigned(FFirstChild) then
    if FFirstChild.IsValid then Result := FFirstChild
    else begin
      FFirstChild.Free;
      Result := GetFirstChild
    end
  else
    if IsDirectory then begin
      R := FindFirst(BuildFileName(FileName, '*'), faAnyFile, SR);
      if R = 0 then begin
        FFirstChild := TFileSystemNode.Create(Owner as TFileSystem, Self, SR);
        FFirstChild.FreeNotification(Self);
        Result := FFirstChild
      end
      else FindClose(SR)
    end
end;

function TFileSystemNode.GetNext: TFileSystemNode;
var
  R: Longint;
  SR: TSearchRec;
begin
  Result := nil;
  if Assigned(FNext) then
    if FNext.IsValid then Result := FNext
    else begin
      FNext.Free;
      Result := GetNext
    end
  else begin
    SR := FSearchRecord;
    R := FindNext(SR);
    if R = 0 then begin
      FNext := TFileSystemNode.Create(Owner as TFileSystem, Parent, SR);
      FNext.FreeNotification(Self);
      Result := FNext
    end
    else begin
      FindClose(SR);
    end;
  end;
end;

function TFileSystemNode.GetNodeName: string;
begin
  Result := FSearchRecord.Name;
  if Result = '' then Result := '/'
end;

function TFileSystemNode.GetPrevious: TFileSystemNode;
var
  x: TFileSystemNode;
begin
  Result := nil;
  if Self = Root then Exit;
  if Parent <> nil then begin
    x := Parent.FirstChild;
    if x = Self then Exit;
    while Assigned(x) do
      if x.Next = Self then begin
        Result := x;
        Break
      end
      else x := x.Next
  end
end;

function TFileSystemNode.GetRoot: TFileSystemNode;
begin
  Result := (Owner as TFileSystem).Root
end;

procedure TFileSystemNode.SetPrevious(AValue: TFileSystemNode);
begin
  if AValue = Previous then Exit;
  if Previous = Parent.FirstChild then begin
    Parent.FFirstChild.Free;
    Parent.FFirstChild := AValue;
    Parent.FFirstChild.FreeNotification(Self)
  end
  else
    with Previous.Previous do begin
      FNext.Free;
      FNext := AValue;
      FNext.FreeNotification(Self);
    end;
end;

procedure TFileSystemNode.SetRoot(AValue: TFileSystemNode);
begin
  (Owner as TFileSystem).FRoot := AValue
end;

procedure TFileSystemNode.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  case Operation of
    opRemove:
      if AComponent <> nil then
        if AComponent = FFirstChild then begin
          FFirstChild.RemoveFreeNotification(Self);
          FFirstChild := nil
        end
        else if AComponent = FNext then begin
          FNext.RemoveFreeNotification(Self);
          FNext := nil
        end
        else if AComponent = FParent then begin
          FParent.RemoveFreeNotification(Self);
        end;
  end;
end;

class function TFileSystem.GetNodeSeparator: string;
begin
{$ifdef Windows}
  Result := '\'
{$else}
  Result := '/'
{$endif}
end;

constructor TFileSystemNode.Create(AFileSystem: TFileSystem; ANodeName: string);
var
  SR: TSearchRec;
  R: Longint;
begin
  inherited Create(AFileSystem);
  R := FindFirst(ANodeName, faAnyFile, SR);
  if R = 0 then begin
    FSearchRecord := SR;
  end
  else raise Exception.CreateFmt('File "%s" does not exist.', [ANodeName])
end;

constructor TFileSystemNode.Create(AFileSystem: TFileSystem;
  AParent: TFileSystemNode; ASearchRec: TSearchRec);
begin
  inherited Create(AFileSystem);
  FSearchRecord := ASearchRec;
  FParent := AParent;
  FParent.FreeNotification(Self);
end;

destructor TFileSystemNode.Destroy;
begin
  FFirstChild.Free;
  FNext.Free;
  inherited Destroy;
end;

function TFileSystemNode.IsDirectory: Boolean;
begin
  Result := FSearchRecord.Attr and faDirectory <> 0;
end;

function TFileSystemNode.IsValid: Boolean;
begin
  if IsDirectory then Result := DirectoryExists(FileName)
  else Result := FileExists(FileName)
end;

end.

