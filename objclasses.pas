type
  TFontClass = class
  private
    FVram: PByte;
    FFont: Pointer;
    FXSize, FYSize: integer;
    procedure putfont8(x, y: integer; color: Byte; c: Char); stdcall;
  public
    constructor Create;
    procedure putfont8_asc(x, y: integer; color: Byte; str: PChar); stdcall;
  end;

  TScreenClass = class
  private
    FVram: PByte;
    FXSize, FYSize: integer;
  public
    constructor Create;
    procedure boxfill8(c, x0, y0, x1, y1: integer); stdcall;
    procedure init_screen8(xsize, ysize: integer); stdcall;
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
end;

procedure TFontClass.putfont8(x, y: integer; color: Byte; c: Char); stdcall;
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
      p[0] := color;
    if b and $40 <> 0 then
      p[1] := color;
    if b and $20 <> 0 then
      p[2] := color;
    if b and $10 <> 0 then
      p[3] := color;
    if b and $08 <> 0 then
      p[4] := color;
    if b and $04 <> 0 then
      p[5] := color;
    if b and $02 <> 0 then
      p[6] := color;
    if b and $01 <> 0 then
      p[7] := color;
  end;
end;

procedure TFontClass.putfont8_asc(x, y: integer; color: Byte;
  str: PChar); stdcall;
var
  i: integer;
begin
  i := 0;
  while str[i] <> '' do
  begin
    putfont8(x, y, color, str[i]);
    inc(x, 8);
    inc(i);
  end;
end;

{ ScreenClass }

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

procedure TScreenClass.init_screen8(xsize, ysize: integer); stdcall;
begin
  boxfill8(col8_008484, 0, 0, xsize - 1, ysize - 29);
  boxfill8(col8_c6c6c6, 0, ysize - 28, xsize - 1, ysize - 28);
  boxfill8(col8_ffffff, 0, ysize - 27, xsize - 1, ysize - 27);
  boxfill8(col8_c6c6c6, 0, ysize - 26, xsize - 1, ysize - 1);

  boxfill8(col8_ffffff, 3, ysize - 24, 59, ysize - 24);
  boxfill8(col8_ffffff, 2, ysize - 24, 2, ysize - 4);
  boxfill8(col8_848484, 3, ysize - 4, 59, ysize - 4);
  boxfill8(col8_848484, 59, ysize - 23, 59, ysize - 5);
  boxfill8(col8_000000, 2, ysize - 3, 59, ysize - 3);
  boxfill8(col8_000000, 60, ysize - 24, 60, ysize - 3);

  boxfill8(col8_848484, xsize - 47, ysize - 24, xsize - 4, ysize - 24);
  boxfill8(col8_848484, xsize - 47, ysize - 23, xsize - 47, ysize - 4);
  boxfill8(col8_ffffff, xsize - 47, ysize - 3, xsize - 4, ysize - 3);
  boxfill8(col8_ffffff, xsize - 3, ysize - 24, xsize - 3, ysize - 3);
end;
