unit FSysView;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs, PairSplitter,
  ComCtrls;

type
  TFileSystemView = class;

  { TFileSystemTreeView }

  TFileSystemTreeView = class(TTreeView)
  private
    function GetFileSystemView: TFileSystemView;
    property FSView: TFileSystemView read GetFileSystemView;
  end;

  { TFileListView }

  TFileListView = class(TListView)
  private
    function GetFileSystemView: TFileSystemView;
    property FSView: TFileSystemView read GetFileSystemView;
  end;

  { TFileSystemView }

  TFileSystemView = class(TPairSplitter)
  private
    FDirectory: string;
    FFileListView: TFileListView;
    FFSTreeView: TFileSystemTreeView;
    function GetFileListView: TFileListView;
    function GetFSTreeView: TFileSystemTreeView;
    procedure SetDirectory(AValue: string);
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

{ TFileSystemView }

constructor TFileSystemView.Create(AOwner: TComponent);
var
  SR: TSearchRec;
  R: Longint;
  Root, TN: TTreeNode;
  FD: TFileDescription;
begin
  inherited Create(AOwner);
  R := FindFirst('/', faDirectory, SR);
  if R = 0 then begin
    FD := TFileDescription.Create;
    Move(SR, FD.FSR, SizeOf(SR));
    Root := FSTreeView.Items.AddObjectFirst(nil, '/', FD);
  end;
  FindClose(SR);
  R := FindFirst('/*', faDirectory, SR);
  Directory := GetEnvironmentVariable('HOME');
  TN := FSTreeView.Items.FindNodeWithTextPath('Directory');
  if TN = nil then TN := FSTreeView.Items.AddObject(Root, Directory, FD);
end;

procedure TFileSystemView.Loaded;
begin
  inherited Loaded;
  if Directory = '' then Directory := GetEnvironmentVariable('HOME')
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
    FSTreeView.Align := alClient
  end;
  Result := FFSTreeView
end;

procedure TFileSystemView.SetDirectory(AValue: string);
var
  R: Longint;
  SR: TSearchRec;
  FD: TFileDescription;
  TN: TTreeNode;
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
