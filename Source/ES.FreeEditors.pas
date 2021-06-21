{******************************************************************************}
{                                                                              }
{                       EsVclComponents/EsVclCore v4.0                         }
{                           errorsoft(c) 2009-2021                             }
{                                                                              }
{                     More beautiful things: errorsoft.org                     }
{                                                                              }
{    errorsoft@mail.ru | github.com/errorcalc | habrahabr.ru/user/error1024    }
{          You can write to me in the Telegram messenger: @errorsoft           }
{                                                                              }
{           Star me github: github.com/errorcalc/FreeEsVclComponents           }
{                                                                              }
{                 You can order developing vcl/fmx components,                 }
{               please submit your requests to mail or telegram.               }
{          �� ������ �������� ���������� VCL/FMX ���������� �� �����.          }
{                                                                              }
{******************************************************************************}
unit ES.FreeEditors;

{$I EsDefines.inc}

interface

uses
  DesignEditors, DesignIntf, DesignConst, System.Classes, WinApi.Windows, Vcl.Graphics,
  Vcl.ImgList, PicEdit, VclEditors, Vcl.Imaging.PngImage, System.Types, System.TypInfo
  {$IFDEF VER340UP}, Vcl.BaseImageCollection {$ENDIF};

type
  TEsPngPropertyFix = class(TGraphicProperty)
    procedure Edit; override;
  end;

  TEsPicturePropertyFix = class(TPictureProperty)
    procedure Edit; override;
  end;

  TEsCustomImageIndexProperty = class(TIntegerProperty, ICustomPropertyListDrawing)
  private const
    MaxWidth = 64;
    Border = 2;
  protected
    function GetImageList: TCustomImageList; virtual;
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;

    // ICustomPropertyListDrawing
    procedure ListMeasureHeight(const Value: string; ACanvas: TCanvas; var AHeight: Integer);
    procedure ListMeasureWidth(const Value: string; ACanvas: TCanvas; var AWidth: Integer);
    procedure ListDrawValue(const Value: string; ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
  end;

  {$IFDEF VER340UP}
  TEsCustomImageNameProperty = class(TStringProperty, ICustomPropertyListDrawing)
  private const
    MaxWidth = 64;
    Border = 2;
  protected
    function GetImageList: TCustomImageList; virtual;
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;

    // ICustomPropertyListDrawing
    procedure ListMeasureHeight(const Value: string; ACanvas: TCanvas; var AHeight: Integer);
    procedure ListMeasureWidth(const Value: string; ACanvas: TCanvas; var AWidth: Integer);
    procedure ListDrawValue(const Value: string; ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
  end;

  TEsCustomCollectionImageNameProperty = class(TStringProperty, ICustomPropertyListDrawing)
  private const
    ConstWidth = 32;
    Border = 2;
  protected
    function GetImageCollection: TCustomImageCollection; virtual;
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;

    // ICustomPropertyListDrawing
    procedure ListMeasureHeight(const Value: string; ACanvas: TCanvas; var AHeight: Integer);
    procedure ListMeasureWidth(const Value: string; ACanvas: TCanvas; var AWidth: Integer);
    procedure ListDrawValue(const Value: string; ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
  end;

  TEsCustomCollectionImageIndexProperty = class(TIntegerProperty, ICustomPropertyListDrawing)
  private const
    ConstWidth = 32;
    Border = 2;
  protected
    function GetImageCollection: TCustomImageCollection; virtual;
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;

    // ICustomPropertyListDrawing
    procedure ListMeasureHeight(const Value: string; ACanvas: TCanvas; var AHeight: Integer);
    procedure ListMeasureWidth(const Value: string; ACanvas: TCanvas; var AWidth: Integer);
    procedure ListDrawValue(const Value: string; ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
  end;
  {$ENDIF}

implementation

uses
  System.SysUtils, System.Math, ES.ExGraphics;

{TEsPngPropertyFix}

// AlphaControls/alphaskins is bad.
// I has too much head pain, because of them!
// Alpha controls COMPLETLY BREAK DOWN STANDART PNG LOADER.
procedure TEsPngPropertyFix.Edit;
var
  PictureEditor: TPictureEditor;
  Png: TPngImage;

begin
  PictureEditor := TPictureEditor.Create(nil);
  try
    PictureEditor.GraphicClass := TGraphicClass(GetTypeData(GetPropType)^.ClassType);
    PictureEditor.Picture.Graphic := TGraphic(Pointer(GetOrdValue));

    if PictureEditor.Execute then
      if (PictureEditor.Picture.Graphic = nil) or
         (PictureEditor.Picture.Graphic is PictureEditor.GraphicClass) then
        SetOrdValue(LongInt(PictureEditor.Picture.Graphic))
      else
        if (PictureEditor.Picture.Graphic is TBitmap) and
           PictureEditor.Picture.Graphic.ClassNameIs('TPNGGraphic') then
        begin
          Png := TPngImage.Create;
          try
            BitmapAssignToPngImage(Png, TBitmap(PictureEditor.Picture.Graphic), False);
            SetOrdValue(LongInt(Png));
          finally
            Png.Free;
          end;
        end
        else
          raise Exception.CreateRes(@SInvalidFormat);
  finally
    PictureEditor.Free;
  end;
end;

{ TEsCustomImageIndexProperty }

function TEsCustomImageIndexProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paValueList, paDialog] -
    [paSortList, paMultiSelect, paAutoUpdate, paSubProperties, paReadOnly];
end;

function TEsCustomImageIndexProperty.GetImageList: TCustomImageList;
begin
  if System.TypInfo.GetPropInfo(GetComponent(0), 'Images') <> nil then
    Result := TCustomImageList(System.TypInfo.GetObjectProp(GetComponent(0), 'Images'))
  else
  if System.TypInfo.GetPropInfo(GetComponent(0), 'ImageList') <> nil then
    Result := TCustomImageList(System.TypInfo.GetObjectProp(GetComponent(0), 'ImageList'))
  else
    Result := nil;
end;

procedure TEsCustomImageIndexProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
begin
  if GetImageList <> nil then
    for I := 0 to GetImageList.Count - 1 do
      Proc(IntToStr(I));
end;

procedure TEsCustomImageIndexProperty.ListDrawValue(const Value: string; ACanvas: TCanvas;
  const ARect: TRect; ASelected: Boolean);
var
  R: TRect;
  Index, H: Integer;
  ClipRegion: HRGN;
begin
  R := ARect;
  try
    Index := StrToInt(Value);
    ACanvas.FillRect(R);
    if (GetImageList <> nil) and (Index > -1) then
    begin
      H := R.Bottom - R.Top;
      R.Right := R.Left + Min(MaxWidth, GetImageList.Width);

      ClipRegion := CreateRectRgn(R.Left + Border, R.Top + Border,
        R.Left + Border + Min(MaxWidth, GetImageList.Width), R.Top + Border + H);
      try
        SelectClipRgn(ACanvas.Handle, ClipRegion);
        GetImageList.Draw(ACanvas, R.Left + Border, R.Top + Border, Index, True);
      finally
        SelectClipRgn(ACanvas.Handle, 0);
        DeleteObject(ClipRegion);
      end;

      R := Rect(R.Right + 4, R.Top, ARect.Right, R.Bottom);
    end;
  finally
    DefaultPropertyListDrawValue(Value, ACanvas, R, ASelected);
  end;
end;

procedure TEsCustomImageIndexProperty.ListMeasureHeight(const Value: string; ACanvas: TCanvas;
  var AHeight: Integer);
begin
  if GetImageList <> nil then
    AHeight := Max(ACanvas.TextHeight('Wg|'), Min(GetImageList.Height, MaxWidth) + Border * 2);
end;

procedure TEsCustomImageIndexProperty.ListMeasureWidth(const Value: string; ACanvas: TCanvas;
  var AWidth: Integer);
begin
 if GetImageList <> nil then
    AWidth := AWidth + Min(GetImageList.Height, MaxWidth) + Border * 2;
end;

{$IFDEF VER340UP}

{ TEsCustomImageNameProperty }

function TEsCustomImageNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paValueList, paDialog] -
    [paSortList, paMultiSelect, paAutoUpdate, paSubProperties, paReadOnly];
end;

function TEsCustomImageNameProperty.GetImageList: TCustomImageList;
begin
  if System.TypInfo.GetPropInfo(GetComponent(0), 'Images') <> nil then
    Result := TCustomImageList(System.TypInfo.GetObjectProp(GetComponent(0), 'Images'))
  else
  if System.TypInfo.GetPropInfo(GetComponent(0), 'ImageList') <> nil then
    Result := TCustomImageList(System.TypInfo.GetObjectProp(GetComponent(0), 'ImageList'))
  else
    Result := nil;
end;

procedure TEsCustomImageNameProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
begin
  if GetImageList <> nil then
    if GetImageList.IsImageNameAvailable then
      for I := 0 to GetImageList.Count - 1 do
        Proc(GetImageList.GetNameByIndex(I));
end;

procedure TEsCustomImageNameProperty.ListDrawValue(const Value: string;
  ACanvas: TCanvas; const ARect: TRect; ASelected: Boolean);
var
  R: TRect;
  Index, H: Integer;
  ClipRegion: HRGN;
begin
  Index := 0;
  R := ARect;
  try
    ACanvas.FillRect(R);
    if GetImageList <> nil then
    begin
      H := R.Bottom - R.Top;
      R.Right := R.Left + Min(MaxWidth, GetImageList.Width);

      ClipRegion := CreateRectRgn(R.Left + Border, R.Top + Border,
        R.Left + Border + Min(MaxWidth, GetImageList.Width), R.Top + Border + H);
      try
        SelectClipRgn(ACanvas.Handle, ClipRegion);
        Index := GetImageList.GetIndexByName(Value);
        if Index <> -1 then
          GetImageList.Draw(ACanvas, R.Left + Border, R.Top + Border, Index, True);
      finally
        SelectClipRgn(ACanvas.Handle, 0);
        DeleteObject(ClipRegion);
      end;

      R := Rect(R.Right + 4, R.Top, ARect.Right, R.Bottom);
    end;
  finally
    DefaultPropertyListDrawValue(Value + ' [' + IntToStr(Index) + ']' , ACanvas, R, ASelected);
  end;
end;

procedure TEsCustomImageNameProperty.ListMeasureHeight(const Value: string;
  ACanvas: TCanvas; var AHeight: Integer);
begin
  if GetImageList <> nil then
    AHeight := Max(ACanvas.TextHeight('Wg|'), Min(GetImageList.Height, MaxWidth) + Border * 2);
end;

procedure TEsCustomImageNameProperty.ListMeasureWidth(const Value: string;
  ACanvas: TCanvas; var AWidth: Integer);
begin
  if GetImageList <> nil then
    AWidth := AWidth + Min(GetImageList.Height, MaxWidth) + Border * 2;
end;

{ TEsCustomCollectionImageNameProperty }

function TEsCustomCollectionImageNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paValueList, paDialog] -
    [paSortList, paMultiSelect, paAutoUpdate, paSubProperties, paReadOnly];
end;

function TEsCustomCollectionImageNameProperty.GetImageCollection: TCustomImageCollection;
begin
  if System.TypInfo.GetPropInfo(GetComponent(0), 'ImageCollection') <> nil then
    Result := TCustomImageCollection(System.TypInfo.GetObjectProp(GetComponent(0), 'ImageCollection'))
  else
    Result := nil;
end;

procedure TEsCustomCollectionImageNameProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
begin
  if GetImageCollection <> nil then
    for I := 0 to GetImageCollection.Count - 1 do
      Proc(GetImageCollection.GetNameByIndex(I));
end;

procedure TEsCustomCollectionImageNameProperty.ListDrawValue(
  const Value: string; ACanvas: TCanvas; const ARect: TRect;
  ASelected: Boolean);
var
  R, ImageR: TRect;
  Index: Integer;
  ClipRegion: HRGN;
begin
  Index := 0;
  R := ARect;
  try
    ACanvas.FillRect(R);
    if GetImageCollection <> nil then
    begin
      ImageR := Rect(
        ARect.Left + Border, ARect.Top + Border,
        ARect.Left + Border + ConstWidth, ARect.Top + Border + ConstWidth);
      ClipRegion := CreateRectRgn(ImageR.Left, ImageR.Top, ImageR.Right, ImageR.Bottom);
      try
        SelectClipRgn(ACanvas.Handle, ClipRegion);
        Index := GetImageCollection.GetIndexByName(Value);
        if Index <> -1 then
          GetImageCollection.Draw(ACanvas, ImageR, Index, True);
      finally
        SelectClipRgn(ACanvas.Handle, 0);
        DeleteObject(ClipRegion);
      end;

      R := Rect(ImageR.Right + 4, ARect.Top, ARect.Right, ARect.Bottom);
    end;
  finally
    DefaultPropertyListDrawValue(Value + ' [' + IntToStr(Index) + ']' , ACanvas, R, ASelected);
  end;
end;

procedure TEsCustomCollectionImageNameProperty.ListMeasureHeight(
  const Value: string; ACanvas: TCanvas; var AHeight: Integer);
begin
  if GetImageCollection <> nil then
    AHeight := Max(ACanvas.TextHeight('Wg|'), ConstWidth + Border * 2);
end;

procedure TEsCustomCollectionImageNameProperty.ListMeasureWidth(
  const Value: string; ACanvas: TCanvas; var AWidth: Integer);
begin
  if GetImageCollection <> nil then
    AWidth := AWidth + ConstWidth + Border * 2;
end;

{ TEsCustomCollectionImageIndexProperty }

function TEsCustomCollectionImageIndexProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited GetAttributes + [paValueList, paDialog] -
    [paSortList, paMultiSelect, paAutoUpdate, paSubProperties, paReadOnly];
end;

function TEsCustomCollectionImageIndexProperty.GetImageCollection: TCustomImageCollection;
begin
  if System.TypInfo.GetPropInfo(GetComponent(0), 'ImageCollection') <> nil then
    Result := TCustomImageCollection(System.TypInfo.GetObjectProp(GetComponent(0), 'ImageCollection'))
  else
    Result := nil;
end;

procedure TEsCustomCollectionImageIndexProperty.GetValues(Proc: TGetStrProc);
var
  I: Integer;
begin
  if GetImageCollection <> nil then
    for I := 0 to GetImageCollection.Count - 1 do
      Proc(IntToStr(I));
end;

procedure TEsCustomCollectionImageIndexProperty.ListDrawValue(
  const Value: string; ACanvas: TCanvas; const ARect: TRect;
  ASelected: Boolean);
var
  R, ImageR: TRect;
  Index: Integer;
  Name: string;
  ClipRegion: HRGN;
begin
  Name := '';
  R := ARect;
  try
    Index := StrToInt(Value);
    ACanvas.FillRect(R);
    if GetImageCollection <> nil then
    begin
      ImageR := Rect(
        ARect.Left + Border, ARect.Top + Border,
        ARect.Left + Border + ConstWidth, ARect.Top + Border + ConstWidth);
      ClipRegion := CreateRectRgn(ImageR.Left, ImageR.Top, ImageR.Right, ImageR.Bottom);
      try
        SelectClipRgn(ACanvas.Handle, ClipRegion);
        if GetImageCollection.IsIndexAvailable(Index) then
          GetImageCollection.Draw(ACanvas, ImageR, Index, True);
      finally
        SelectClipRgn(ACanvas.Handle, 0);
        DeleteObject(ClipRegion);
      end;

      R := Rect(ImageR.Right + 4, ARect.Top, ARect.Right, ARect.Bottom);
      Name := ' [' + GetImageCollection.GetNameByIndex(Index) + ']';
    end;
  finally
    DefaultPropertyListDrawValue(Value + Name, ACanvas, R, ASelected);
  end;
end;

procedure TEsCustomCollectionImageIndexProperty.ListMeasureHeight(
  const Value: string; ACanvas: TCanvas; var AHeight: Integer);
begin
  if GetImageCollection <> nil then
    AHeight := Max(ACanvas.TextHeight('Wg|'), ConstWidth + Border * 2);
end;

procedure TEsCustomCollectionImageIndexProperty.ListMeasureWidth(
  const Value: string; ACanvas: TCanvas; var AWidth: Integer);
begin
  if GetImageCollection <> nil then
    AWidth := AWidth + ConstWidth + Border * 2;
end;
{$ENDIF}

{ TEsPicturePropertyFix }

// AlphaControls/alphaskins COMPLETLY BREAK DOWN STANDART PNG LOADER.
// I has too much head pain, because of them!
procedure TEsPicturePropertyFix.Edit;
var
  Png: TPngImage;
  Pic: TPicture;
begin
  Inherited;
  Pic := TPicture(Pointer(GetOrdValue));
  if (Pic.Graphic is TBitmap) and Pic.Graphic.ClassNameIs('TPNGGraphic') then
  begin
    Png := TPngImage.Create;
    try
      BitmapAssignToPngImage(Png, TBitmap(Pic.Graphic), False);
      Pic.Assign(Png);
    finally
      Png.Free;
    end;
  end;
end;

end.
