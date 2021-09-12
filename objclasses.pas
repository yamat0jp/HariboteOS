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
    procedure boxfill8(c, x0, y0, x1, y1: integer); stdcall;
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
  end;

  { TFontClass }

constructor TFontClass.Create;
var
  bootinfo: ^TMultiboot_hdr;
begin
  bootinfo := Pointer(0);
  FVram := PByte(bootinfo^.screen_addr);
  FFont := bootinfo^.font_addr;
  FXSize := bootinfo^.width;
  FYSize := bootinfo^.height;
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
  FXSize := hdr^.width;
  FYSize := hdr^.height;
end;

procedure TScreenClass.boxfill8(c, x0, y0, x1, y1: integer); stdcall;
var
  x, y: integer;
begin
  for y := y0 to y1 do
    for x := x0 to x1 do
      FVram[y * FXSize + x] := Byte(c);
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
  FXSize := hdr^.width;
  FYSize := hdr^.height;
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
  if cursor = nil then
    cursor := FDefault;
  x:=0;
  y:=0;
  repeat
    case cursor[x] of
      '*':
        FMouse[16 * y + x] := col8_000000;
      '0':
        FMouse[16 * y + x] := col8_ffffff;
      '.':
        FMouse[16 * y + x] := Yellow;
    end;
    if x > 15 then
    begin
      x := 0;
      inc(y);
    end;
  until y > 15;
end;

procedure TMouseClass.putblock8_8(px, py: integer; buf: PByte; bxsize: integer);
var
  x, y: integer;
begin
  for y := 0 to FYSize - 1 do
    for x := 0 to FXSize - 1 do
      FVram[(py + y) * FXSize + px + x] := buf[y * bxsize + x];
end;
