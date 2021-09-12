type
  TFontClass = class
  private
    FVram: PByte;
    FFont: Pointer;
    FXSize, FYSize: integer;
    FColor: Byte;
    procedure putfont8(x, y: integer; c: Char);
  public
    constructor Create;
    procedure putfont8_asc(x, y: integer; str: PChar); stdcall;
    property color: Byte read FColor write FColor;
  end;

  TScreenClass = class
  private
    FVram: PByte;
    FXSize, FYSize: integer;
  public
    constructor Create;
    procedure boxfill8(color: Byte; x0, y0, x1, y1: integer); stdcall;
    procedure init_screen8; stdcall;
  end;

  TMouseClass = class
  private
    FVram: PByte;
    FXSize, FYSize: integer;
    FWid, FHei: integer;
    FCursor, FDefault: PChar;
    FMouse: PByte;
    procedure init_mouse_cursor8(cursor: PChar);
    procedure putblock8_8(px, py: integer; buf: PByte; bxsize: integer);
  public
    constructor Create;
    property Width: integer read FWid write FWid;
    property Height: integer read FHei write FHei;
  end;

  TKeyFifoClass = class
  private
    FFifo: TQueue;
    FSize: integer;
    procedure inthandler21(esp: integer);
    function GetCount: integer;
  public
    constructor Create;
    destructor Destroy; override;
    function fifo8_push(data: Char): Boolean; stdcall;
    function fifo8_pop: Char; stdcall;
    property Size: integer read FSize write FSize;
    property Count: integer read GetCount;
  end;

  { TFontClass }

constructor TFontClass.Create;
var
  bootinfo: ^TMultiboot_hdr;
begin
  bootinfo := Pointer(0);
  FVram := PByte(bootinfo^.screen_addr);
  FFont := bootinfo^.font_addr;
  FXSize := bootinfo^.Width;
  FYSize := bootinfo^.Height;
  FColor := Blue;
end;

procedure TFontClass.putfont8(x, y: integer; c: Char);
type
  TFont = array [0 .. 16] of Byte;
var
  i: integer;
  pdata: ^TFont;
  b: Byte;
  p: PByte;
begin
  pdata := FFont;
  for i := 0 to 16 do
  begin
    p := FVram + (y + i) * FXSize + x;
    b := pdata^[i];
    if b and $80 <> 0 then
      p[0] := FColor;
    if b and $40 <> 0 then
      p[1] := FColor;
    if b and $20 <> 0 then
      p[2] := FColor;
    if b and $10 <> 0 then
      p[3] := FColor;
    if b and $08 <> 0 then
      p[4] := FColor;
    if b and $04 <> 0 then
      p[5] := FColor;
    if b and $02 <> 0 then
      p[6] := FColor;
    if b and $01 <> 0 then
      p[7] := FColor;
  end;
end;

procedure TFontClass.putfont8_asc(x, y: integer; str: PChar); stdcall;
var
  i: integer;
begin
  i := 0;
  while str[i] <> '' do
  begin
    putfont8(x, y, str[i]);
    inc(x, 8);
    inc(i);
  end;
end;

{ TScreenClass }

constructor TScreenClass.Create;
var
  hdr: ^TMultiboot_hdr;
begin
  hdr := Pointer(0);
  FVram := hdr^.screen_addr;
  FXSize := hdr^.Width;
  FYSize := hdr^.Height;
end;

procedure TScreenClass.boxfill8(color: Byte; x0, y0, x1, y1: integer); stdcall;
var
  x, y: integer;
begin
  for y := y0 to y1 do
    for x := x0 to x1 do
      FVram[y * FXSize + x] := Byte(color);
end;

procedure TScreenClass.init_screen8; stdcall;
begin
  boxfill8(col8_008484, 0, 0, FXSize - 1, FYSize - 29);
  boxfill8(col8_c6c6c6, 0, FYSize - 28, FXSize - 1, FYSize - 28);
  boxfill8(col8_ffffff, 0, FYSize - 27, FXSize - 1, FYSize - 27);
  boxfill8(col8_c6c6c6, 0, FYSize - 26, FXSize - 1, FYSize - 1);

  boxfill8(col8_ffffff, 3, FYSize - 24, 59, FYSize - 24);
  boxfill8(col8_ffffff, 2, FYSize - 24, 2, FYSize - 4);
  boxfill8(col8_848484, 3, FYSize - 4, 59, FYSize - 4);
  boxfill8(col8_848484, 59, FYSize - 23, 59, FYSize - 5);
  boxfill8(col8_000000, 2, FYSize - 3, 59, FYSize - 3);
  boxfill8(col8_000000, 60, FYSize - 24, 60, FYSize - 3);

  boxfill8(col8_848484, FXSize - 47, FYSize - 24, FXSize - 4, FYSize - 24);
  boxfill8(col8_848484, FXSize - 47, FYSize - 23, FXSize - 47, FYSize - 4);
  boxfill8(col8_ffffff, FXSize - 47, FYSize - 3, FXSize - 4, FYSize - 3);
  boxfill8(col8_ffffff, FXSize - 3, FYSize - 24, FXSize - 3, FYSize - 3);
end;

{ TMouseClass }

constructor TMouseClass.Create;
var
  hdr: ^TMultiboot_hdr;
begin
  hdr := Pointer(0);
  FVram := hdr^.screen_addr;
  FXSize := hdr^.Width;
  FYSize := hdr^.Height;
  FWid := 16;
  FHei := 16;
  init_mouse_cursor8(nil);
end;

procedure TMouseClass.init_mouse_cursor8(cursor: PChar);
var
  x, y: integer;
  procedure build(data: array of string);
  var
    i, j, k: integer;
  begin
    k := 0;
    for j := 1 to 16 do
      for i := 1 to 16 do
      begin
        FDefault[k] := data[j, i];
        inc(k);
      end;
  end;

begin
  if cursor = nil then
  begin
    build([ //
      '**************..', //
      '*00000000000*...', //
      '*0000000000*....', //
      '*000000000*.....', //
      '*00000000*......', //
      '*0000000*.......', //
      '*0000000*.......', //
      '*00000000*......', //
      '*0000**000*.....', //
      '*000*..*000*....', //
      '*00*....*000*...', //
      '*0*......*000*..', //
      '**........*000*.', //
      '*..........*000*', //
      '............*00*', //
      '.............***']);
    FCursor := FDefault;
  end
  else
    FCursor := cursor;
  x := 0;
  y := 0;
  repeat
    case FCursor[x] of
      '*':
        FMouse[FWid * y + x] := col8_000000;
      '0':
        FMouse[FWid * y + x] := col8_ffffff;
      '.':
        FMouse[FWid * y + x] := Yellow;
    end;
    if x >= FWid then
    begin
      x := 0;
      inc(y);
    end;
  until y >= FHei;
end;

procedure TMouseClass.putblock8_8(px, py: integer; buf: PByte; bxsize: integer);
var
  x, y: integer;
begin
  for y := 0 to FYSize - 1 do
    for x := 0 to FXSize - 1 do
      FVram[(py + y) * FXSize + px + x] := buf[y * bxsize + x];
end;

{ KeyFifoClass }

constructor TKeyFifoClass.Create;
begin
  FFifo := TQueue.Create;
  FSize := 32;
end;

destructor TKeyFifoClass.Destroy;
begin
  FFifo.Free;
  inherited;
end;

function TKeyFifoClass.fifo8_push(data: Char): Boolean; stdcall;
var
  p: PChar;
begin
  if FFifo.Count < FSize then
  begin
    New(p);
    p^ := data;
    FFifo.Push(p);
    result := true;
  end
  else
    result := false;
end;

function TKeyFifoClass.fifo8_pop: Char; stdcall;
var
  p: PCHar;
begin
  if FFifo.Count > 0 then
  begin
    p := FFifo.Pop;
    result := p^;
    Dispose(p);
  end
  else
    result := #0;
end;

procedure TKeyFifoClass.inthandler21(esp: integer);
var
  data: Char;
  key: TKeyFifoClass;
begin
  io_out8(PIC0_OCW2, $61);
  data := Char(io_in8(PORT_KEYDAT));
  key:=TKeyFifoClass.Create;
  try
    key.fifo8_push(data);
  finally
    key.Free;
  end;
end;

function TKeyFifoClass.GetCount: integer;
begin
  result:=FFifo.Count;
end;
