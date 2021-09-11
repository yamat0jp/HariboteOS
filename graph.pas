
procedure boxfill8(vram: PByte; xsize: integer; b: Byte;
  x0, y0, x1, y1: integer); stdcall;
var
  x, y: integer;
begin
  for y := y0 to y1 do
    for x := x0 to x1 do
      vram[y * xsize + x] := b;
end;

procedure putfont8(vram: PByte; width, x, y: integer; color: Byte;
  font: Pointer); stdcall;
type
  TFont = array [0 .. 16] of Byte;
var
  i: integer;
  pdata: ^TFont;
  b: Byte;
  p: PByte;
  xsize: integer;
begin
  pdata := font;
  xsize := 320;
  for i := 0 to 16 do
  begin
    p := vram + (y + i) * xsize + x;
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

procedure putfont8_asc(vram: PByte; xsize, x, y: integer; b: Byte;
  s, t: PChar); stdcall;
var
  i: integer;
begin
  i := 0;
  while s[i] <> '' do
  begin
    putfont8(vram, xsize, x, y, b, t + i * 16);
    inc(x, 8);
    inc(i);
  end;
end;

procedure set_palette(start, stop: integer; rgb: PByte); stdcall;
var
  i, eflags: integer;
begin
  eflags := io_load_eflags;
  io_cli;
  io_out8($03C8, start);
  for i := start to stop do
  begin
    io_out8($03C9, rgb[0] shr 4);
    io_out8($03C9, rgb[1] shr 4);
    io_out8($03C9, rgb[2] shr 4);
    inc(rgb, 3);
  end;
  io_store_eflags(eflags);
end;

procedure init_palette; stdcall;
var
  table_rgb: array [0 .. 16 * 3] of Byte;
  procedure setting(data: array of Byte);
  var
    i: integer;
  begin
    for i := 0 to High(data) do
      table_rgb[i] := data[i];
  end;

begin
  setting([$00, $00, $00, $FF, $00, $00, $00, $FF, $00, $FF, $FF, $00, $00, $00,
    $FF, $FF, $00, $FF, $00, $FF, $FF, $C6, $C6, $C6, $84, $00, $00, $00, $84,
    $00, $84, $84, $00, $00, $84, $84, $84, $84, $84]);
  set_palette(0, 15, @table_rgb);
end;

procedure init_screen8(vram: PByte; xsize, ysize: integer); stdcall;
begin
  boxfill8(vram, xsize, col8_008484, 0, 0, xsize - 1, ysize - 29);
  boxfill8(vram, xsize, col8_c6c6c6, 0, ysize - 28, xsize - 1, ysize - 28);
  boxfill8(vram, xsize, col8_ffffff, 0, ysize - 27, xsize - 1, ysize - 27);
  boxfill8(vram, xsize, col8_c6c6c6, 0, ysize - 26, xsize - 1, ysize - 1);

  boxfill8(vram, xsize, col8_ffffff, 3, ysize - 24, 59, ysize - 24);
  boxfill8(vram, xsize, col8_ffffff, 2, ysize - 24, 2, ysize - 4);
  boxfill8(vram, xsize, col8_848484, 3, ysize - 4, 59, ysize - 4);
  boxfill8(vram, xsize, col8_848484, 59, ysize - 23, 59, ysize - 5);
  boxfill8(vram, xsize, col8_000000, 2, ysize - 3, 59, ysize - 3);
  boxfill8(vram, xsize, col8_000000, 60, ysize - 24, 60, ysize - 3);

  boxfill8(vram, xsize, col8_848484, xsize - 47, ysize - 24, xsize - 4,
    ysize - 24);
  boxfill8(vram, xsize, col8_848484, xsize - 47, ysize - 23, xsize - 47,
    ysize - 4);
  boxfill8(vram, xsize, col8_ffffff, xsize - 47, ysize - 3, xsize - 4,
    ysize - 3);
  boxfill8(vram, xsize, col8_ffffff, xsize - 3, ysize - 24, xsize - 3,
    ysize - 3);
  putfont8(vram, xsize, 8, 8, 100, Pointer($0000C520 + 1));
end;

