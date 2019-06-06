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
    property FSTreeView: TFileSystemTreeView read GetFSTreeView;
    property FileListView: TFileListView read GetFileListView;
  published
    property Directory: string read FDirectory write SetDirectory;
  end;

procedure Register;

implementation

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
begin
  inherited Create(AOwner);

end;

function TFileSystemView.GetFileListView: TFileListView;
begin
  if not Assigned(FFileListView) then begin
    FFileListView := TFileListView.Create(Self);
    FFileListView.Parent := Sides[0];
  end;
  Result := FFileListView
end;

function TFileSystemView.GetFSTreeView: TFileSystemTreeView;
begin
  if not Assigned(FFSTreeView) then begin
    FFSTreeView := TFileSystemTreeView.Create(Self);
    FFSTreeView.Parent := Sides[1];
  end;
  Result := FFSTreeView
end;

procedure TFileSystemView.SetDirectory(AValue: string);
begin
  {Baumansicht und Dateilistenansicht für den Knoten Directory erstellen}
  FDirectory := AValue
end;

end.
