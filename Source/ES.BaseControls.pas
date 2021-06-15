{******************************************************************************}
{                       EsVclComponents/EsVclCore v3.0                         }
{                           errorsoft(c) 2009-2018                             }
{                                                                              }
{                     More beautiful things: errorsoft.org                     }
{                                                                              }
{           errorsoft@mail.ru | vk.com/errorsoft | github.com/errorcalc        }
{              errorsoft@protonmail.ch | habrahabr.ru/user/error1024           }
{                                                                              }
{         Open this on github: github.com/errorcalc/FreeEsVclComponents        }
{                                                                              }
{ You can order developing vcl/fmx components, please submit requests to mail. }
{ �� ������ �������� ���������� VCL/FMX ���������� �� �����.                   }
{******************************************************************************}

{
  This is the base unit, which must remain Delphi 7 support, and it should not
  be dependent on any other units!
}

unit ES.BaseControls;

{$I EsDefines.inc}

// see function CalcClientRect
{$define FAST_CALC_CLIENTRECT}

// see TEsBaseLayout.ContentRect
{$define TEST_CONTROL_CONTENT_RECT}

interface

uses
  WinApi.Windows, System.Types, System.Classes, Vcl.Controls,
  Vcl.Graphics, Vcl.Forms, WinApi.Messages, WinApi.Uxtheme, Vcl.Themes;

const
  CM_ESBASE = CM_BASE + $0800;
  CM_PARENT_BUFFEREDCHILDRENS_CHANGED = CM_ESBASE + 1;

  EsVclCoreVersion = 3.0;

type
  THelperOption = (hoPadding, hoBorder, hoClientRect);
  THelperOptions = set of THelperOption;

  TPaintEvent = procedure(Sender: TObject; Canvas: TCanvas; Rect: TRect) of object;

  /// <summary>
  /// The best replacement for TCustomControl, supports transparency and without flicker
  /// </summary>
  TEsCustomControl = class(TWinControl)
  private
    FIsCachedBuffer: Boolean;
    FIsFullSizeBuffer: Boolean;
    FIsCachedBackground: Boolean;


    // anti flicker and transparent magic
    FCanvas: TCanvas;
    CacheBitmap: HBITMAP;// Cache for buffer BitMap
    CacheBackground: HBITMAP;// Cache for background BitMap

    FBufferedChildren: Boolean;
    FParentBufferedChildren: Boolean;

    // paint events
    FOnPaint: TPaintEvent;
    FOnPainting: TPaintEvent;
    // draw helper
    FIsDrawHelper: Boolean;
    // paint
    procedure SetIsCachedBuffer(Value: Boolean);
    procedure SetIsCachedBackground(Value: Boolean);
    procedure SetIsDrawHelper(const Value: Boolean);
    procedure SetIsOpaque(const Value: Boolean);
    function GetIsOpaque: Boolean;
    procedure SetBufferedChildren(const Value: Boolean);
    procedure SetParentBufferedChildren(const Value: Boolean);
    function GetTransparent: Boolean;
    procedure SetTransparent(const Value: Boolean);
    function IsBufferedChildrenStored: Boolean;
    // handle messages
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMEraseBkgnd(var Message: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMWindowPosChanged(var Message: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
    procedure WMSize(var Message: TWMSize); message WM_SIZE;
    procedure CMParentBufferedChildrensChanged(var Message: TMessage); message CM_PARENT_BUFFEREDCHILDRENS_CHANGED;
    procedure DrawBackgroundForOpaqueControls(DC: HDC);
    // intercept mouse
    // procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    // other
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure WMTextChanges(var Message: TMessage); message WM_SETTEXT;
    // fix
    procedure FixBufferedChildren(Reader: TReader);
    procedure FixParentBufferedChildren(Reader: TReader);
    procedure SetIsFullSizeBuffer(const Value: Boolean);
  protected
    // fix
    procedure DefineProperties(Filer: TFiler); override;
    // paint
    property Canvas: TCanvas read FCanvas;
    procedure DeleteCache;
    procedure Paint; virtual;
    procedure PaintWindow(DC: HDC); override;
    procedure PaintHandler(var Message: TWMPaint);
    procedure DrawBackground(DC: HDC); virtual;
    procedure FillBackground(Handle: THandle); virtual;
    // other
    procedure UpdateText; dynamic;
    {$IFDEF STYLE_ELEMENTS}
    procedure UpdateStyleElements; override;
    {$ENDIF}
    //
    property ParentBackground default True;
    property Transparent: Boolean read GetTransparent write SetTransparent default True;// analog of ParentBackground
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure UpdateBackground(Repaint: Boolean); overload;
    procedure UpdateBackground; overload;
    // ------------------ Properties for published -----------------------------
    /// <summary>
    /// Standard double buffering, this control uses its own improved buffering, therefore this property is False by default.
    /// If standard DoubleBuffering is enabled then improved buffering of child graphics controls has been disabled.
    /// </summary>
    property DoubleBuffered default False;
    /// <summary>
    /// See the DoubleBuffering property description for details.
    /// </summary>
    property ParentDoubleBuffered default False;
    /// <summary>
    /// OnPaint event handler, called after the control content has been rendered.
    /// </summary>
    property OnPaint: TPaintEvent read FOnPaint write FOnPaint;
    /// <summary>
    /// OnPainting event handler, called before the control content has been rendered.
    /// </summary>
    property OnPainting: TPaintEvent read FOnPainting write FOnPainting;
    /// <summary>
    /// ParentDoubleBuffered property similar to ParentDoubleBuffered property but related to BufferedChildren.
    /// </summary>
    property ParentBufferedChildren: Boolean read FParentBufferedChildren write SetParentBufferedChildren default True;
    /// <summary>
    /// BufferedChildren is an improved double buffering that suppresses flickering for child graphics controls.
    /// </summary>
    property BufferedChildren: Boolean read FBufferedChildren write SetBufferedChildren stored IsBufferedChildrenStored;
    /// <summary>
    /// If IsCachedBuffer is true, then the double buffering buffer will be persisted between draw calls, this is faster,
    /// but causes more memory consumption.
    /// </summary>
    property IsCachedBuffer: Boolean read FIsCachedBuffer write SetIsCachedBuffer default False;
    /// <summary>
    /// IsCachedBackground allows you to persist the background image between draw calls.
    /// Accelerates rendering, but when the background changes, you must manually call Invalidate.
    /// </summary>
    property IsCachedBackground: Boolean read FIsCachedBackground write SetIsCachedBackground default False;
    /// <summary>
    /// If True then control will be drawing the halt-tone frame, helps to more accurately position the control in the design time.
    /// </summary>
    property IsDrawHelper: Boolean read FIsDrawHelper write SetIsDrawHelper default False;
    /// <summary>
    /// IsOpaque are analogue [csOpaque] in ControlStyle.
    /// </summary>
    property IsOpaque: Boolean read GetIsOpaque write SetIsOpaque default False;
    /// <summary>
    /// If the property is active, then the bitmap buffer will be for the entire size of the control.
    /// More cpu and mem usage, but for some code that does not take into account the context shift, this is a solution to problems.
    /// </summary>
    property IsFullSizeBuffer: Boolean read FIsFullSizeBuffer write SetIsFullSizeBuffer default False;
  end;

  TContentMargins = record
  type
    TMarginSize = 0..MaxInt;
  private
    Left: TMarginSize;
    Top: TMarginSize;
    Right: TMarginSize;
    Bottom: TMarginSize;
  public
    function Width: TMarginSize;
    function Height: TMarginSize;
    procedure Inflate(DX, DY: Integer); overload;
    procedure Inflate(DLeft, DTop, DRight, DBottom: Integer); overload;
    procedure Reset;
    constructor Create(Left, Top, Right, Bottom: TMarginSize); overload;
  end;

  /// <summary> ONLY INTERNAL USE! THIS CLASS CAN BE DELETED! (USE TEsCustomControl OR TEsCustomLayot) </summary>
  TEsBaseLayout = class(TEsCustomControl)
  private
    FBorderWidth: TBorderWidth;
    procedure SetBorderWidth(const Value: TBorderWidth);
  protected
    procedure AlignControls(AControl: TControl; var Rect: TRect); override;
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure Paint; override;
    // new
    procedure CalcContentMargins(var Margins: TContentMargins); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    function ContentRect: TRect; virtual;
    function ContentMargins: TContentMargins; inline;
    property BorderWidth: TBorderWidth read FBorderWidth write SetBorderWidth default 0;
    property BufferedChildren default True;
  end;

  /// <summary> The GraphicControl, supports Padding and IsDrawHelper property </summary>
  TEsGraphicControl = class(TGraphicControl)
  private
    FPadding: TPadding;
    FIsDrawHelper: Boolean;
    function GetPadding: TPadding;
    procedure SetPadding(const Value: TPadding);
    procedure PaddingChange(Sender: TObject);
    procedure SetIsDrawHelper(const Value: Boolean);
  protected
    procedure Paint; override;
    function HasPadding: Boolean;
    {$IFDEF STYLE_ELEMENTS}
    procedure UpdateStyleElements; override;
    {$ENDIF}
    // new
    procedure CalcContentMargins(var Margins: TContentMargins); virtual;
  public
    destructor Destroy; override;
    property Padding: TPadding read GetPadding write SetPadding;
    function ContentRect: TRect; virtual;
    function ContentMargins: TContentMargins; inline;
    property IsDrawHelper: Boolean read FIsDrawHelper write SetIsDrawHelper default False;
  end;

  procedure DrawControlHelper(Control: TControl; Options: THelperOptions; FrameWidth: Integer = 0); overload;
  procedure DrawControlHelper(Canvas: TCanvas; Rect: TRect; BorderWidth: TBorderWidth;
    Padding: TPadding; Options: THelperOptions); overload;

  function CalcClientRect(Control: TControl): TRect;

  procedure DrawParentImage(Control: TControl; DC: HDC; InvalidateParent: Boolean = False);

implementation

uses
  System.SysUtils, System.TypInfo;

type
  TOpenCtrl = class(TWinControl)
  public
    property BorderWidth;
  end;


{$REGION 'DrawControlHelper'}
procedure DrawControlHelper(Canvas: TCanvas; Rect: TRect; BorderWidth: TBorderWidth;
  Padding: TPadding; Options: THelperOptions);
  procedure Line(Canvas: TCanvas; x1, y1, x2, y2: Integer);
  begin
    Canvas.MoveTo(x1, y1);
    Canvas.LineTo(x2, y2);
  end;
var
  SaveBk: TColor;
  SavePen, SaveBrush: TPersistent;
begin
  SavePen := nil;
  SaveBrush := nil;

  try
    if Canvas.Handle = 0 then
      Exit;

    // save canvas state
    SavePen := TPen.Create;
    SavePen.Assign(Canvas.Pen);
    SaveBrush := TBrush.Create;
    SaveBrush.Assign(Canvas.Brush);

    Canvas.Pen.Mode := pmNot;
    Canvas.Pen.Style := psDash;
    Canvas.Brush.Style := bsClear;

    // ClientRect Helper
    if THelperOption.hoClientRect in Options then
    begin
      SaveBk := SetBkColor(Canvas.Handle, RGB(127,255,255));
      DrawFocusRect(Canvas.Handle, Rect);
      SetBkColor(Canvas.Handle, SaveBk);
    end;

    // Border Helper
    if THelperOption.hoBorder in Options then
    begin
      if (BorderWidth <> 0) and (BorderWidth * 2 <= RectWidth(Rect)) and (BorderWidth * 2 <= RectHeight(Rect)) then
        Canvas.Rectangle(Rect.Left + BorderWidth, Rect.Top + BorderWidth,
          Rect.Right - BorderWidth, Rect.Bottom - BorderWidth);
    end;

    // Padding Helper
    if THelperOption.hoPadding in Options then
    begin
      if (BorderWidth + Padding.Top < RectHeight(Rect) - BorderWidth - Padding.Bottom) and
         (BorderWidth + Padding.Left < RectWidth(Rect) - BorderWidth - Padding.Right) then
      begin
        Canvas.Pen.Style := psDot;

        if Padding.Left <> 0 then
          Line(Canvas, Rect.Left + Padding.Left + BorderWidth, Rect.Top + Padding.Top + BorderWidth,
            Rect.Left + Padding.Left + BorderWidth, Rect.Bottom - Padding.Bottom - BorderWidth - 1);
        if Padding.Top <> 0 then
          Line(Canvas, Rect.Left + Padding.Left + BorderWidth, Rect.Top + Padding.Top + BorderWidth,
            Rect.Right - Padding.Right - BorderWidth - 1, Rect.Top + Padding.Top + BorderWidth);
        if Padding.Right <> 0 then
          Line(Canvas, Rect.Right - Padding.Right - BorderWidth - 1, Rect.Top + Padding.Top + BorderWidth,
            Rect.Right - Padding.Right - BorderWidth - 1, Rect.Bottom - Padding.Bottom - BorderWidth - 1);
        if Padding.Bottom <> 0 then
          Line(Canvas, Rect.Left + Padding.Left + BorderWidth, Rect.Bottom - Padding.Bottom - BorderWidth - 1,
            Rect.Right - Padding.Right - BorderWidth - 1, Rect.Bottom - Padding.Bottom - BorderWidth - 1);
      end;
    end;

    Canvas.Pen.Assign(SavePen);
    Canvas.Brush.Assign(SaveBrush);
  finally
    SavePen.Free;
    SaveBrush.Free;
  end;
end;

procedure DrawControlHelper(Control: TControl; Options: THelperOptions;
  FrameWidth: Integer = 0);
var
  Canvas: TCanvas;
  Padding: TPadding;
  BorderWidth: Integer;
  MyCanvas: Boolean;
  R: TRect;
begin
  MyCanvas := False;
  Canvas := nil;
  Padding := nil;
  BorderWidth := 0;

  // if win control
  if Control is TWinControl then
  begin
    TOpenCtrl(Control).AdjustClientRect(R);

    // get padding
    Padding := TWinControl(Control).Padding;
    // get canvas
    if Control is TEsCustomControl then
      Canvas := TEsCustomControl(Control).Canvas
    else
    begin
      MyCanvas := True;
      Canvas := TControlCanvas.Create;
      TControlCanvas(Canvas).Control := Control;
    end;
    // get border width
    if Control is TEsBaseLayout then
      BorderWidth := TEsBaseLayout(Control).BorderWidth
    else
      BorderWidth := TOpenCtrl(Control).BorderWidth;
  end else
  if Control is TGraphicControl then
  begin
    // get canvas
    Canvas := TEsGraphicControl(Control).Canvas;
    if Control is TEsGraphicControl then
      Padding := TEsGraphicControl(Control).Padding;
  end;

  try
    R := Control.ClientRect;
    R.Inflate(-FrameWidth, -FrameWidth);
    DrawControlHelper(Canvas, R, BorderWidth, Padding, Options);
  finally
    if MyCanvas then
      Canvas.Free;
  end;
end;
{$ENDREGION}

function IsStyledClientControl(Control: TControl): Boolean;
begin
  Result := False;

  {$IFDEF STYLE_NAME}
  if StyleServices(Control).Enabled then
  begin
    Result := (seClient in Control.StyleElements) and
              (not StyleServices(Control).IsSystemStyle);
  end;
  {$ELSE}
  if StyleServices.Enabled then
  begin
    Result := {$IFDEF STYLE_ELEMENTS}(seClient in Control.StyleElements) and{$ENDIF}
      TStyleManager.IsCustomStyleActive;
  end;
  {$ENDIF}
end;

function CalcClientRect(Control: TControl): TRect;
var
  {$IFDEF FAST_CALC_CLIENTRECT}
  Info: TWindowInfo;
  {$ENDIF}
  IsFast: Boolean;
begin
  {$IFDEF FAST_CALC_CLIENTRECT}
  IsFast := True;
  {$ELSE}
  IsFast := False;
  {$ENDIF}

  Result := Rect(0, 0, Control.Width, Control.Height);

  // Only TWinControl's has non client area
  if not (Control is TWinControl) then
    Exit;

  // Fast method not work for controls not having Handle
  if not TWinControl(Control).Handle <> 0 then
    IsFast := False;

  if IsFast then
  begin
    ZeroMemory(@Info, SizeOf(TWindowInfo));
    Info.cbSize := SizeOf(TWindowInfo);
    GetWindowInfo(TWinControl(Control).Handle, info);
    Result.Left := Info.rcClient.Left - Info.rcWindow.Left;
    Result.Top := Info.rcClient.Top - Info.rcWindow.Top;
    Result.Right := -Info.rcWindow.Left + Info.rcClient.Right;
    Result.Top := -Info.rcWindow.Top + Info.rcClient.Bottom;
  end else
  begin
    Control.Perform(WM_NCCALCSIZE, 0, LParam(@Result));
  end;
end;

procedure DrawParentImage(Control: TControl; DC: HDC; InvalidateParent: Boolean = False);
var
  ClientRect: TRect;
  P: TPoint;
  SaveIndex: Integer;
begin
  if Control.Parent = nil then
    Exit;
  SaveIndex := SaveDC(DC);
  GetViewportOrgEx(DC, P);

  // if control has non client border then need additional offset viewport
  ClientRect := Control.ClientRect;
  if (ClientRect.Right <> Control.Width) or (ClientRect.Bottom <> Control.Height) then
  begin
    ClientRect := CalcClientRect(Control);
    SetViewportOrgEx(DC, P.X - Control.Left - ClientRect.Left, P.Y - Control.Top - ClientRect.Top, nil);
  end else
    SetViewportOrgEx(DC, P.X - Control.Left, P.Y - Control.Top, nil);

  IntersectClipRect(DC, 0, 0, Control.Parent.ClientWidth, Control.Parent.ClientHeight);

  Control.Parent.Perform(WM_ERASEBKGND, DC, 0);
  Control.Parent.Perform(WM_PRINTCLIENT, DC, PRF_CLIENT);

  RestoreDC(DC, SaveIndex);

  if InvalidateParent then
    if not (Control.Parent is TCustomControl) and not (Control.Parent is TCustomForm) and
       not (csDesigning in Control.ComponentState)and not (Control.Parent is TEsCustomControl) then
    begin
      Control.Parent.Invalidate;
    end;

  SetViewportOrgEx(DC, P.X, P.Y, nil);
end;

procedure BitmapDeleteAndNil(var Bitmap: HBITMAP);
begin
  if Bitmap <> 0 then
  begin
    DeleteObject(Bitmap);
    Bitmap := 0;
  end;
end;

procedure TEsCustomControl.CMParentBufferedChildrensChanged(var Message: TMessage);
begin
  if FParentBufferedChildren then
  begin
    if Parent <> nil then
    begin
      if Parent is TEsCustomControl then
        BufferedChildren := TEsCustomControl(Parent).BufferedChildren
      else
        BufferedChildren := False;
    end;
    FParentBufferedChildren := True;
  end;
end;

procedure TEsCustomControl.CMTextChanged(var Message: TMessage);
begin
  inherited;
  UpdateText;
end;

procedure TEsCustomControl.WMTextChanges(var Message: TMessage);
begin
  Inherited;
  UpdateText;
end;


constructor TEsCustomControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // init
  ControlStyle := ControlStyle - [csOpaque] + [csParentBackground];
  ParentDoubleBuffered := False;

  CacheBitmap := 0;
  CacheBackground := 0;

  // canvas
  FCanvas := TControlCanvas.Create;
  TControlCanvas(FCanvas).Control := Self;

  // new props
  FParentBufferedChildren := True;
  FBufferedChildren := False;
  FIsCachedBuffer := False;
  FIsCachedBackground := False;
  FIsFullSizeBuffer := False;
  FIsDrawHelper := False;
end;

// temp fix
procedure TEsCustomControl.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('BufferedChildrens', FixBufferedChildren, nil, False);
  Filer.DefineProperty('ParentBufferedChildrens', FixParentBufferedChildren, nil, False);
end;

// ok
procedure TEsCustomControl.DeleteCache;
begin
  BitmapDeleteAndNil(CacheBitmap);
  BitmapDeleteAndNil(CacheBackground);
end;

destructor TEsCustomControl.Destroy;
begin
  FCanvas.Free;
  DeleteCache;
  inherited;
end;

procedure TEsCustomControl.DrawBackground(DC: HDC);
begin
  DrawParentImage(Self, DC, False);
end;

// hack for bad graphic controls
procedure TEsCustomControl.DrawBackgroundForOpaqueControls(DC: HDC);
var
  i: integer;
  Control: TControl;
  Prop: Pointer;
begin
  for i := 0 to ControlCount - 1 do
  begin
    Control := Controls[i];
    if (Control is TGraphicControl) and (csOpaque in Control.ControlStyle) and Control.Visible and
       (not (csDesigning in ComponentState) or not (csNoDesignVisible in ControlStyle)
        or not (csDesignerHide in Control.ControlState))
    then
    begin
      // Necessary to draw a background if the control has a Property 'Transparent' and hasn't a Property 'Color'
      Prop := GetPropInfo(Control.ClassInfo, 'Transparent');
      if Prop <> nil then
      begin
        Prop := GetPropInfo(Control.ClassInfo, 'Color');
        if Prop = nil then
          FillRect(DC, Rect(Control.Left, Control.Top, Control.Left + Control.Width, Control.Top + Control.Height), Brush.Handle);
      end;
    end;
  end;
end;

// temp fix
procedure TEsCustomControl.FillBackground(Handle: THandle);
begin
  if not IsStyledClientControl(Self) then
  begin
    FillRect(Handle, ClientRect, Brush.Handle)
  end else
  begin
    {$IFDEF STYLE_NAME}
    SetDCBrushColor(Handle, StyleServices(Self).GetSystemColor(Color));
    {$ELSE}
    SetDCBrushColor(Handle, StyleServices.GetSystemColor(Color);
    {$ENDIF}
    FillRect(Handle, ClientRect, GetStockObject(DC_BRUSH));
  end;
end;

procedure TEsCustomControl.FixBufferedChildren(Reader: TReader);
begin
  BufferedChildren := Reader.ReadBoolean;
end;

// temp fix
procedure TEsCustomControl.FixParentBufferedChildren(Reader: TReader);
begin
  ParentBufferedChildren := Reader.ReadBoolean;
end;

function TEsCustomControl.GetIsOpaque: Boolean;
begin
  Result := csOpaque in ControlStyle;
end;

function TEsCustomControl.GetTransparent: Boolean;
begin
  Result := ParentBackground;
end;

procedure TEsCustomControl.Paint;
var
  SaveBk: TColor;
begin
  // for Design time
  if IsDrawHelper and(csDesigning in ComponentState) then
  begin
    SaveBk := SetBkColor(Canvas.Handle, RGB(127,255,255));
    DrawFocusRect(Canvas.Handle, Self.ClientRect);
    SetBkColor(Canvas.Handle, SaveBk);
  end;
end;

{ TODO -cCRITICAL : 22.02.2013:
  eliminate duplication of code! }
procedure TEsCustomControl.PaintHandler(var Message: TWMPaint);
var
  PS: TPaintStruct;
  BufferDC: HDC;
  BufferBitMap: HBITMAP;
  UpdateRect: TRect;
  SaveViewport: TPoint;
  Region: HRGN;
  DC: HDC;
  NeedBeginPaint: Boolean;
begin
  BufferBitMap := 0;
  BufferDC := 0;
  DC := 0;
  Region := 0;
  NeedBeginPaint := Message.DC = 0;

  try
    if NeedBeginPaint then
    begin
      DC := BeginPaint(Handle, PS);
      if {$IFDEF STYLE_NAME} not StyleServices(Self).IsSystemStyle {$ELSE} TStyleManager.IsCustomStyleActive {$ENDIF} and
        not FIsCachedBuffer then
        UpdateRect := ClientRect
        // I had to use a crutch to ClientRect, due to the fact that
        // VCL.Styles.TCustomStyle.DoDrawParentBackground NOT use relative coordinates,
        // ie ignores SetViewportOrgEx!
        // This function uses ClientToScreen and ScreenToClient for coordinates calculation!
      else
        UpdateRect := PS.rcPaint;
    end
    else
    begin
      DC := Message.DC;
      if {$IFDEF STYLE_NAME} not StyleServices(Self).IsSystemStyle {$ELSE} TStyleManager.IsCustomStyleActive {$ENDIF} and
        not FIsCachedBuffer then
        UpdateRect := ClientRect
      else
        if GetClipBox(DC, UpdateRect) = ERROR then
          UpdateRect := ClientRect;
    end;

    //------------------------------------------------------------------------------------------------
    // Duplicate code, see PaintWindow, Please sync this code!!!
    //------------------------------------------------------------------------------------------------
    // if control not double buffered then create or assign buffer
    if not DoubleBuffered then
    begin
      BufferDC := CreateCompatibleDC(DC);
      // CreateCompatibleDC(DC) return 0 if Drawing takes place to MemDC(buffer):
      // return <> 0 => need to double buffer || return = 0 => no need to double buffer
      if BufferDC <> 0 then
      begin
        // Using the cache if possible
        if FIsCachedBuffer or FIsFullSizeBuffer then
        begin
          // Create cache if need
          if CacheBitmap = 0 then
          begin
            BufferBitMap := CreateCompatibleBitmap(DC, ClientWidth, ClientHeight);
            // Assign to cache if need
            if FIsCachedBuffer then
              CacheBitmap := BufferBitMap;
          end
          else
            BufferBitMap := CacheBitmap;

          // Assign region for minimal overdraw
          Region := CreateRectRgnIndirect(UpdateRect);//0, 0, UpdateRect.Width, UpdateRect.Height);
          SelectClipRgn(BufferDC, Region);
        end
        else
          // Create buffer
          BufferBitMap := CreateCompatibleBitmap(DC,
            UpdateRect.Right - UpdateRect.Left, UpdateRect.Bottom - UpdateRect.Top);
        // Select buffer bitmap
        SelectObject(BufferDC, BufferBitMap);
        // [change coord], if need
        // Moving update region to the (0,0) point
        if not(FIsCachedBuffer or FIsFullSizeBuffer) then
        begin
          GetViewportOrgEx(BufferDC, SaveViewport);
          SetViewportOrgEx(BufferDC, -UpdateRect.Left + SaveViewport.X, -UpdateRect.Top + SaveViewport.Y, nil);
        end;
      end
      else
        BufferDC := DC;
    end
    else
      BufferDC := DC;
    //------------------------------------------------------------------------------------------------

    // DEFAULT HANDLER:
    Message.DC := BufferDC;
    inherited PaintHandler(Message);

  finally
    try
      //------------------------------------------------------------------------------------------------
      // Duplicate code, see PaintWindow, Please sync this code!!!
      //------------------------------------------------------------------------------------------------
      try
        // draw to window
        if not DoubleBuffered then
        begin
          if not(FIsCachedBuffer or FIsFullSizeBuffer) then
          begin
            // [restore coord], if need
            SetViewportOrgEx(BufferDC, SaveViewport.X, SaveViewport.Y, nil);
            BitBlt(DC, UpdateRect.Left, UpdateRect.Top, RectWidth(UpdateRect), RectHeight(UpdateRect), BufferDC, 0, 0, SRCCOPY);
          end
          else
          begin
            BitBlt(DC, UpdateRect.Left, UpdateRect.Top, RectWidth(UpdateRect), RectHeight(UpdateRect), BufferDC,
              UpdateRect.Left, UpdateRect.Top, SRCCOPY);
          end;
        end;
      finally
        if BufferDC <> DC then
          DeleteObject(BufferDC);
        if Region <> 0 then
          DeleteObject(Region);
        // delete buffer, if need
        if not FIsCachedBuffer and (BufferBitMap <> 0) then
          DeleteObject(BufferBitMap);
      end;
      //------------------------------------------------------------------------------------------------
    finally
      // end paint, if need
      if NeedBeginPaint then
        EndPaint(Handle, PS);
    end;
  end;
end;

{ TODO -cMAJOR : 22.02.2013:
 See: PaintHandler,
 need eliminate duplication of code! }
procedure TEsCustomControl.PaintWindow(DC: HDC);
var
  TempDC: HDC;
  UpdateRect: TRect;
  //---
  BufferDC: HDC;
  BufferBitMap: HBITMAP;
  Region: HRGN;
  SaveViewport: TPoint;
  BufferedThis: Boolean;
begin
  BufferBitMap := 0;
  Region := 0;
  BufferDC := 0;

  if GetClipBox(DC, UpdateRect) = ERROR then
    UpdateRect := ClientRect;

  BufferedThis := not BufferedChildren;

  // fix for designer selection
  BufferedThis := BufferedThis or (csDesigning in ComponentState);

  try
    if BufferedThis then
    begin
    //------------------------------------------------------------------------------------------------
    // Duplicate code, see PaintHandler, Please sync this code!!!
    //------------------------------------------------------------------------------------------------
      // if control not double buffered then create or assign buffer
      if not DoubleBuffered then
      begin
        BufferDC := CreateCompatibleDC(DC);
        // CreateCompatibleDC(DC) return 0 if Drawing takes place to MemDC(buffer):
        // return <> 0 => need to double buffer || return = 0 => no need to double buffer
        if BufferDC <> 0 then
        begin
          // Using the cache if possible
          if FIsCachedBuffer or FIsFullSizeBuffer then
          begin
            // Create cache if need
            if CacheBitmap = 0 then
            begin
              BufferBitMap := CreateCompatibleBitmap(DC, ClientWidth, ClientHeight);
              // Assign to cache if need
              if FIsCachedBuffer then
                CacheBitmap := BufferBitMap;
            end
            else
              BufferBitMap := CacheBitmap;

            // Assign region for minimal overdraw
            Region := CreateRectRgnIndirect(UpdateRect);//0, 0, UpdateRect.Width, UpdateRect.Height);
            SelectClipRgn(BufferDC, Region);
          end
          else
            // Create buffer
            BufferBitMap := CreateCompatibleBitmap(DC, RectWidth(UpdateRect), RectHeight(UpdateRect));
          // Select buffer bitmap
          SelectObject(BufferDC, BufferBitMap);
          // [change coord], if need
          // Moving update region to the (0,0) point
          if not(FIsCachedBuffer or FIsFullSizeBuffer) then
          begin
            GetViewportOrgEx(BufferDC, SaveViewport);
            SetViewportOrgEx(BufferDC, -UpdateRect.Left + SaveViewport.X, -UpdateRect.Top + SaveViewport.Y, nil);
          end;
        end
        else
          BufferDC := DC;
      end
      else
        BufferDC := DC;
    //------------------------------------------------------------------------------------------------
    end else
      BufferDC := DC;

    if not(csOpaque in ControlStyle) then
      if ParentBackground then
      begin
        if FIsCachedBackground then
        begin
          if CacheBackground = 0 then
          begin
            TempDC := CreateCompatibleDC(DC);
            CacheBackground := CreateCompatibleBitmap(DC, ClientWidth, ClientHeight);
            SelectObject(TempDC, CacheBackground);
            DrawBackground(TempDC); //DrawParentImage(Self, TempDC, False);
            DeleteDC(TempDC);
          end;
          TempDC := CreateCompatibleDC(BufferDC);
          SelectObject(TempDC, CacheBackground);
          if not FIsCachedBuffer then
            BitBlt(BufferDC, UpdateRect.Left, UpdateRect.Top, RectWidth(UpdateRect), RectHeight(UpdateRect), TempDC,
              UpdateRect.Left, UpdateRect.Top, SRCCOPY)
          else
            BitBlt(BufferDC, UpdateRect.Left, UpdateRect.Top, RectWidth(UpdateRect), RectHeight(UpdateRect), TempDC,
              UpdateRect.Left, UpdateRect.Top, SRCCOPY);
          DeleteDC(TempDC);
        end
        else
          DrawBackground(BufferDC); //DrawParentImage(Self, BufferDC, False);
      end else
        if (not DoubleBuffered or (DC <> 0)) then
          FillBackground(BufferDC);

    FCanvas.Lock;
    try
      Canvas.Handle := BufferDC;
      TControlCanvas(Canvas).UpdateTextFlags;

      if Assigned(FOnPainting) then
        FOnPainting(Self, Canvas, ClientRect);
      Paint;
      if Assigned(FOnPaint) then
        FOnPaint(Self, Canvas, ClientRect);
    finally
      FCanvas.Handle := 0;
      FCanvas.Unlock;
    end;

  finally
    if BufferedThis then
    begin
      //------------------------------------------------------------------------------------------------
      // Duplicate code, see PaintHandler, Please sync this code!!!
      //------------------------------------------------------------------------------------------------
      try
        // draw to window
        if not DoubleBuffered then
        begin
          if not(FIsCachedBuffer or FIsFullSizeBuffer) then
          begin
            // [restore coord], if need
            SetViewportOrgEx(BufferDC, SaveViewport.X, SaveViewport.Y, nil);
            BitBlt(DC, UpdateRect.Left, UpdateRect.Top, RectWidth(UpdateRect), RectHeight(UpdateRect), BufferDC, 0, 0, SRCCOPY);
          end
          else
          begin
            BitBlt(DC, UpdateRect.Left, UpdateRect.Top, RectWidth(UpdateRect), RectHeight(UpdateRect), BufferDC,
              UpdateRect.Left, UpdateRect.Top, SRCCOPY);
          end;
        end;
      finally
        if BufferDC <> DC then
          DeleteObject(BufferDC);
        if Region <> 0 then
          DeleteObject(Region);
        // delete buffer, if need
        if not FIsCachedBuffer and (BufferBitMap <> 0) then
          DeleteObject(BufferBitMap);
      end;
      //------------------------------------------------------------------------------------------------
    end;
  end;
end;

// ok
function TEsCustomControl.IsBufferedChildrenStored: Boolean;
begin
  Result := not ParentBufferedChildren;
end;

{$IFDEF STYLE_ELEMENTS}
procedure TEsCustomControl.UpdateStyleElements;
begin
  Invalidate;
end;
{$ENDIF}

// ok
procedure TEsCustomControl.SetBufferedChildren(const Value: Boolean);
begin
  if Value <> FBufferedChildren then
  begin
    FBufferedChildren := Value;
    FParentBufferedChildren := False;
    NotifyControls(CM_PARENT_BUFFEREDCHILDRENS_CHANGED);
  end;
end;

procedure TEsCustomControl.SetIsCachedBackground(Value: Boolean);
begin
  if Value <> FIsCachedBackground then
  begin
    FIsCachedBackground := Value;
    if not FIsCachedBackground then BitmapDeleteAndNil(CacheBackground);
  end;
end;

procedure TEsCustomControl.SetIsCachedBuffer(Value: Boolean);
begin
  if Value <> FIsCachedBuffer then
  begin
    FIsCachedBuffer := Value;
    if not FIsCachedBuffer then BitmapDeleteAndNil(CacheBitmap);
  end;
end;

procedure TEsCustomControl.SetIsDrawHelper(const Value: Boolean);
begin
  if Value <> FIsDrawHelper then
  begin
    FIsDrawHelper := Value;
    if csDesigning in ComponentState then
      Invalidate;
  end;
end;

procedure TEsCustomControl.SetIsFullSizeBuffer(const Value: Boolean);
begin
  DeleteCache;
end;

// ok
procedure TEsCustomControl.SetIsOpaque(const Value: Boolean);
begin
  if Value <> (csOpaque in ControlStyle) then
  begin
    if Value then
      ControlStyle := ControlStyle + [csOpaque]
    else
      ControlStyle := ControlStyle - [csOpaque];

    Invalidate;
  end;
end;

// ok
procedure TEsCustomControl.SetParentBufferedChildren(const Value: Boolean);
begin
  if Value <> FParentBufferedChildren then
  begin
    FParentBufferedChildren := Value;

    if (Parent <> nil) and not (csReading in ComponentState) then
      Perform(CM_PARENT_BUFFEREDCHILDRENS_CHANGED, 0, 0);
  end;
end;

procedure TEsCustomControl.SetTransparent(const Value: Boolean);
begin
  ParentBackground := Value;
end;

procedure TEsCustomControl.UpdateBackground;
begin
  UpdateBackground(True);
end;

procedure TEsCustomControl.UpdateText;
begin
end;

procedure TEsCustomControl.UpdateBackground(Repaint: Boolean);
begin
  // Delete cache background
  BitmapDeleteAndNil(CacheBackground);

  if Repaint then Invalidate;
end;

procedure TEsCustomControl.WMEraseBkgnd(var Message: TWMEraseBkgnd);
begin
  if DoubleBuffered then
  begin
    inherited;
  end else
  begin
    if ControlCount <> 0 then
      DrawBackgroundForOpaqueControls(Message.DC);
    Message.Result := 1;
  end;
end;

procedure TEsCustomControl.WMPaint(var Message: TWMPaint);
begin
  ControlState := ControlState + [csCustomPaint];

  // buffered childen aviable only for not DoubleBuffered controls
  if BufferedChildren and (not FDoubleBuffered) and
    not (csDesigning in ComponentState) { <- fix for designer selection} then
  begin
    PaintHandler(Message)// My new PaintHandler
  end else
  begin
    inherited;
  end;

  ControlState := ControlState - [csCustomPaint];
end;

procedure TEsCustomControl.WMSize(var Message: TWMSize);
begin
  DeleteCache;
  inherited;
end;

procedure TEsCustomControl.WMWindowPosChanged(var Message: TWMWindowPosChanged);
begin
  if not (csOpaque in ControlStyle) and ParentBackground then
    Invalidate;
  inherited;
end;

{ TEsBaseLayout }

constructor TEsBaseLayout.Create(AOwner: TComponent);
begin
  inherited;

  FBufferedChildren := True;
end;

procedure TEsBaseLayout.AdjustClientRect(var Rect: TRect);
begin
  inherited AdjustClientRect(Rect);
  if BorderWidth <> 0 then
  begin
    InflateRect(Rect, -Integer(BorderWidth), -Integer(BorderWidth));
  end;
end;

procedure TEsBaseLayout.AlignControls(AControl: TControl; var Rect: TRect);
begin
  inherited AlignControls(AControl, Rect);
  if (csDesigning in ComponentState) and IsDrawHelper then
    Invalidate;
end;

procedure TEsBaseLayout.CalcContentMargins(var Margins: TContentMargins);
begin
  Margins.Create(Padding.Left, Padding.Top, Padding.Right, Padding.Bottom);
  if BorderWidth <> 0 then
    Margins.Inflate(Integer(BorderWidth), Integer(BorderWidth));
end;

function TEsBaseLayout.ContentMargins: TContentMargins;
begin
  Result.Reset;
  CalcContentMargins(Result);
end;

function TEsBaseLayout.ContentRect: TRect;
var
  ContentMargins: TContentMargins;
begin
  Result := ClientRect;

  ContentMargins.Reset;
  CalcContentMargins(ContentMargins);

  Result.Left := Result.Left + ContentMargins.Left;
  Result.Top := Result.Top + ContentMargins.Top;
  Result.Right := Result.Right - ContentMargins.Right;
  Result.Bottom := Result.Bottom - ContentMargins.Bottom;

  {$IFDEF TEST_CONTROL_CONTENT_RECT}
  if Result.Left > Result.Right then
    Result.Right := Result.Left;
  if Result.Top > Result.Bottom then
    Result.Bottom := Result.Top;
  {$ENDIF}
end;

procedure TEsBaseLayout.Paint;
begin
  if (csDesigning in ComponentState) and IsDrawHelper then
    DrawControlHelper(Self, [hoBorder, hoPadding, hoClientRect]);
end;

procedure TEsBaseLayout.SetBorderWidth(const Value: TBorderWidth);
begin
  if Value <> FBorderWidth then
  begin
    FBorderWidth := Value;
    Realign;
    Invalidate;
  end;
end;

{ TEsGraphicControl }

procedure TEsGraphicControl.CalcContentMargins(var Margins: TContentMargins);
begin
  if FPadding <> nil then
    Margins.Create(Padding.Left, Padding.Top, Padding.Right, Padding.Bottom)
  else
    Margins.Reset;
end;

function TEsGraphicControl.ContentMargins: TContentMargins;
begin
  Result.Reset;
  CalcContentMargins(Result);
end;

function TEsGraphicControl.ContentRect: TRect;
var
  ContentMargins: TContentMargins;
begin
  Result := ClientRect;

  ContentMargins.Reset;
  CalcContentMargins(ContentMargins);

  Inc(Result.Left, ContentMargins.Left);
  Inc(Result.Top, ContentMargins.Top);
  Dec(Result.Right, ContentMargins.Right);
  Dec(Result.Bottom, ContentMargins.Bottom);

  {$IFDEF TEST_CONTROL_CONTENT_RECT}
  if Result.Left > Result.Right then
    Result.Right := Result.Left;
  if Result.Top > Result.Bottom then
    Result.Bottom := Result.Top;
  {$ENDIF}
end;

destructor TEsGraphicControl.Destroy;
begin
  FPadding.Free;
  inherited;
end;

{$IFDEF STYLE_ELEMENTS}
procedure  TEsGraphicControl.UpdateStyleElements;
begin
  Invalidate;
end;
{$ENDIF}

function TEsGraphicControl.GetPadding: TPadding;
begin
  if FPadding = nil then
  begin
    FPadding := TPadding.Create(nil);
    FPadding.OnChange := PaddingChange;
  end;
  Result := FPadding;
end;

function TEsGraphicControl.HasPadding: Boolean;
begin
  Result := FPadding <> nil;
end;

procedure TEsGraphicControl.PaddingChange(Sender: TObject);
begin
  AdjustSize;
  Invalidate;
  if (FPadding.Left = 0) and (FPadding.Top = 0) and
     (FPadding.Right = 0) and (FPadding.Bottom = 0) then
    FreeAndNil(FPadding);
end;

procedure TEsGraphicControl.Paint;
begin
  if (csDesigning in ComponentState) and IsDrawHelper then
    DrawControlHelper(Self, [hoPadding, hoClientRect]);
end;

procedure TEsGraphicControl.SetIsDrawHelper(const Value: Boolean);
begin
  if FIsDrawHelper <> Value then
  begin
      FIsDrawHelper := Value;
      if csDesigning in ComponentState then
        Invalidate;
  end;
end;

procedure TEsGraphicControl.SetPadding(const Value: TPadding);
begin
  Padding.Assign(Value);
end;

{ TContentMargins }

constructor TContentMargins.Create(Left, Top, Right, Bottom: TMarginSize);
begin
  Self.Left := Left;
  Self.Top := Top;
  Self.Right := Right;
  Self.Bottom := Bottom;
end;

procedure TContentMargins.Reset;
begin
  Left := 0;
  Top := 0;
  Right := 0;
  Bottom := 0;
end;

function TContentMargins.Height: TMarginSize;
begin
  Result := Top + Bottom;
end;

procedure TContentMargins.Inflate(DX, DY: Integer);
begin
  Inc(Left, DX);
  Inc(Right, DX);
  Inc(Top, DY);
  Inc(Bottom, DY);
end;

procedure TContentMargins.Inflate(DLeft, DTop, DRight, DBottom: Integer);
begin
  Inc(Left, DLeft);
  Inc(Right, DRight);
  Inc(Top, DTop);
  Inc(Bottom, DBottom);
end;

function TContentMargins.Width: TMarginSize;
begin
  Result := Left + Right;
end;

end.


