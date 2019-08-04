unit FSysView;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, PairSplitter,
  ComCtrls, FSTree, DTV;

type

  TFileSystemView = class;
  TFileListView = class;

  { TFileSystemTreeView }

  TFileSystemTreeView = class(TDetailledTreeView)
  private
    function GetFileSystemView: TFileSystemView;
    property FSView: TFileSystemView read GetFileSystemView;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  { TFileListView }

  TFileListView = class(TCustomListView)
  private
    function GetFileSystemView: TFileSystemView;
    property FSView: TFileSystemView read GetFileSystemView;
  end;

  { TFileSystemView }

  TFileSystemView = class(TPairSplitter)
  private
    FFileSystem: TFileSystem;
    function GetFileSystem: TFileSystem;
  private
    FDirectory: string;
    FFileListView: TFileListView;
    FFSTreeView: TFileSystemTreeView;
    function GetFileListView: TFileListView;
    function GetFSTreeView: TFileSystemTreeView;
    procedure SetDirectory(AValue: string);
    property FileSystem: TFileSystem read GetFileSystem;
  protected

  public
    constructor Create(AOwner: TComponent); override;
    procedure Loaded; override;
  published
    property Directory: string read FDirectory write SetDirectory;
    property FSTreeView: TFileSystemTreeView read GetFSTreeView;
    property FileListView: TFileListView read GetFileListView;
  end;

procedure Register;

implementation

uses Patch;

type
  TFileDescription = class(TObject)
  private
    FSR: TSearchRec;
  end;

procedure Register;
begin
  RegisterComponents('Misc',[TFileSystemView]);
end;

{ TFileListView }

function TFileListView.GetFileSystemView: TFileSystemView;
begin
  Result := Owner as TFileSystemView
end;

{ TFileSystemTreeView }

function TFileSystemTreeView.GetFileSystemView: TFileSystemView;
begin
  Result := Owner as TFileSystemView
end;

constructor TFileSystemTreeView.Create(AOwner: TComponent);
var
  Data: TFileSystemNode;
  P, TN: TTreeNode;
begin
  inherited Create(AOwner);
  P := Items.AddObjectFirst(nil, FSView.FileSystem.Root.NodeName, FSView.FileSystem.Root);
  Data := FSView.FileSystem.Root.FirstChild;
  if Data <> nil then
    if Data.IsDirectory and (Data.NodeName <> '.') and (Data.NodeName <> '..')
      then TN := Items.AddChildObjectFirst(P, Data.NodeName, Data);
  while Data.Next <> nil do begin
    WriteLn(Data.NodeName);
    Data := Data.Next;
    if Data.IsDirectory and (Data.NodeName <> '.') and (Data.NodeName <> '..')
      then TN := Items.AddChildObject(P, Data.NodeName, Data);
  end;
  P.AlphaSort;
  ReadOnly := True;
end;

{ TFileSystemView }

constructor TFileSystemView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  GetFSTreeView;
end;

procedure TFileSystemView.Loaded;
begin
  inherited Loaded
end;

function TFileSystemView.GetFileSystem: TFileSystem;
begin
  if not Assigned(FFileSystem) then begin
    FFileSystem := TFileSystem.Create(Self);
  end;
  Result := FFileSystem;
end;

function TFileSystemView.GetFileListView: TFileListView;
begin
  if not Assigned(FFileListView) then begin
    FFileListView := TFileListView.Create(Self);
    FFileListView.Parent := Sides[1];
    FFileListView.Align := alClient
  end;
  Result := FFileListView
end;

function TFileSystemView.GetFSTreeView: TFileSystemTreeView;
begin
  if not Assigned(FFSTreeView) then begin
    FFSTreeView := TFileSystemTreeView.Create(Self);
    FFSTreeView.Parent := Sides[0];
    FSTreeView.Align := alClient;
  end;
  Result := FFSTreeView
end;

procedure TFileSystemView.SetDirectory(AValue: string);
var
  R: Longint;
  SR: TSearchRec;
  FD: TFileDescription;
  {TN: TTreeNode;}
begin
  if not False {(csUpdating in ComponentState)} then begin
    {Updating;}
    {R := FindFirst(Directory, faDirectory, SR);
    if R := 0 then begin
      TN := TTreeNode.Create(FSTreeView.Items);
      TN.
      FSTreeView.Items.Add(;
    end;
    FindClose(SR);}
    R := FindFirst(BuildFileName(Directory,  '*'), faDirectory, SR);
    while R = 0 do begin
      FD := TFileDescription.Create;
      Move(SR, FD.FSR, SizeOf(SR));
      FileListView.AddItem(SR.Name, FD);
      Application.ProcessMessages;
      R := FindNext(SR)
    end;
    FindClose(SR);
    {Updated; }
  end;
  FDirectory := AValue;
end;

end.
