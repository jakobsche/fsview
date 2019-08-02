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
    function GetNodeSeparator: string;
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
    function GetNodeName: string;
    function GetPrevious: TFileSystemNode;
    function GetRoot: TFileSystemNode;
    procedure SetPrevious(AValue: TFileSystemNode);
  public
    constructor Create(AFileSystem: TFileSystem; AFileName: string); virtual; overload;
    constructor Create(AFileSystem: TFileSystem; AParent: TFileSystemNode; ASearchRec: TSearchRec); virtual; overload;
    destructor Destroy; override;
    property FileName: string read GetFileName;
    property FirstChild: TFileSystemNode read FFirstChild;
    property Next: TFileSystemNode read FNext;
    property NodeName: string read GetNodeName;
    property Parent: TFileSystemNode read FParent;
    property Previous: TFileSystemNode read GetPrevious write SetPrevious;
    property Root: TFileSystemNode read GetRoot;
  end;

implementation

uses Patch, Op;

{ TFileSystem }

function TFileSystem.GetRoot: TFileSystemNode;
begin
  if not Assigned(FRoot) then
    FRoot := TFileSystemNode.Create(Self, '/');
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

function TFileSystemNode.GetNodeName: string;
begin
  Result := FSearchRecord.Name;
end;

function TFileSystemNode.GetPrevious: TFileSystemNode;
var
  x: TFileSystemNode;
begin
  Result := nil;
  x := Parent.FirstChild;
  if x = Self then Exit;
  while Assigned(x) do
    if x.Next = Self then begin
      Result := x;
      Break
    end
    else x := x.Next
end;

function TFileSystemNode.GetRoot: TFileSystemNode;
begin
  Result := Self;
  while Result.Parent <> nil do Result := Result.Parent
end;

procedure TFileSystemNode.SetPrevious(AValue: TFileSystemNode);
begin
  if Previous = Parent.FirstChild then Parent.FFirstChild := AValue
  else Previous.Previous.FNext := AValue;
end;

function TFileSystem.GetNodeSeparator: string;
begin
{$ifdef Windows}
  Result := '\'
{$else}
  Result := '/'
{$endif}
end;

constructor TFileSystemNode.Create(AFileSystem: TFileSystem; AFileName: string);
var
  P: TFileSystemNode;
  PN: string;
  SR: TSearchRec;
  R: Longint;
begin
  inherited Create(AFileSystem);
  R := FindFirst(AFileName, faDirectory, SR);
  if R = 0 then begin
    FSearchRecord := SR;
    if PN <> '' then begin
      PN := ExtractFilePath(AFileName);
      P := AFileSystem.FindNodeByFileName(PN);
      if P = nil then P := TFileSystemNode.Create(AFileSystem, PN);
      FParent := P
    end
  end
  else raise Exception.CreateFmt('File "%s" does not exist.', [AFileName])
end;

constructor TFileSystemNode.Create(AFileSystem: TFileSystem;
  AParent: TFileSystemNode; ASearchRec: TSearchRec);
begin
  inherited Create(AFileSystem);
  FSearchRecord := ASearchRec;
  FParent := AParent
end;

destructor TFileSystemNode.Destroy;
begin
  FFirstChild.Free;
  if Parent.FirstChild = Self then Parent.FFirstChild := Next
  else Previous := Next;
  inherited Destroy;
end;

end.

