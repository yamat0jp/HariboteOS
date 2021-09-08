program haribote;

{$APPTYPE CONSOLE}
{$R *.res}

uses System.Classes, ShellAPI;

const
  Blue = 1;
  Red = 4;
  Yellow = 14;
  White = 15;

  col8_000000 = 0;
  col8_ff0000 = 1;
  col8_00ff00 = 2;
  col8_ffff00 = 3;
  col8_0000ff = 4;
  col8_ff00ff = 5;
  col8_00ffff = 6;
  col8_ffffff = 7;
  col8_c6c6c6 = 8;
  col8_840000 = 9;
  col8_008400 = 10;
  col8_848400 = 11;
  col8_000084 = 12;
  col8_840084 = 13;
  col8_008484 = 14;
  col8_848484 = 15;

type
  TMultiboot_hdr = packed record
    magic, flags, checksum: cardinal;
    header_addr, load_addr, load_end_addr, bss_end_addr, entry_addr: cardinal;
    mode_type: cardinal;
    width, height, depth: cardinal;
  end;

procedure harimain; stdcall; forward;

procedure loader; stdcall;
asm
  cli
  call harimain
  hlt
end;

procedure io_hlt; stdcall;
asm
  hlt
  ret
end;

procedure io_cli; stdcall;
asm
  cli
  ret
end;

procedure io_sti; stdcall;
asm
  sti
  ret
end;

procedure io_stihlt; stdcall;
asm
  sti
  hlt
  ret
end;

function io_int8(port: integer): Int8; stdcall;
asm
  mov edx,  [esp+4]
  mov eax,  0
  in  al, dx
  ret
end;

function io_int16(port: integer): Int16; stdcall;
asm
  mov edx,  [esp+4]
  mov eax,  0
  in  ax,  dx
  ret
end;

function io_int32(port: integer): Int32; stdcall;
asm
  mov edx,  [esp+4]
  mov eax,  [esp+8]
  out dx, eax
  ret
end;

function io_out8(port, data: integer): integer; stdcall;
begin

end;

function io_load_eflags: integer; stdcall;
asm
  pushfd
  pop eax
  ret
end;

function io_store_eflags(port: integer): integer; stdcall;
asm
  mov eax,  [esp+4]
  push  eax
  popfd
  ret
end;

procedure write_mem8(addr, data: integer); stdcall;
asm
  mov ecx,[esp+4]
  mov al,[esp+8]
  mov [ecx],al
  ret
end;

function screen: PByte; stdcall;
begin
  result := PByte($000B8000);
end;

procedure boxfill8(vram: PByte; xsize: integer; b: Byte;
  x0, y0, x1, y1: integer); stdcall;
var
  x, y: integer;
begin
  for y := y0 to y1 do
    for x := x0 to x1 do
      vram[y * xsize + x] := b;
end;

procedure putfont8(x, y: integer; color: Byte; font: Pointer); stdcall;
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
    p := screen + (y + i) * xsize + x;
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

procedure set_palette(start, stop: integer; rgb: PByte); stdcall;
var
  i, eflags: integer;
begin
  eflags := io_load_eflags;
  io_cli;
  io_out8($03C8, start);
  for i := start to stop do
  begin
    io_out8($03C9, rgb[0] div 4);
    io_out8($03C9, rgb[1] div 4);
    io_out8($03C9, rgb[2] div 4);
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

procedure harimain; stdcall;
var
  i: integer;
  vram: PByte;
  xsize, ysize: integer;
  mult: ^TMultiboot_hdr;
begin
  vram := Pointer($0000);
  xsize := 320;
  ysize := 200;
  for i := 0 to 320 * 200 do
  begin
    screen[3 * i] := 255;
    screen[3 * i + 1] := 255;
    screen[3 * i + 2] := 255;
  end;
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
  putfont8(8, 8, 100, Pointer($0000C520 + 1));
  while true do
    io_hlt;
end;

procedure loader_end; stdcall;
begin

end;

var
  MemoryStream, fs: TMemoryStream;
  pFunc, pBuff: Pointer;
  fwSize, dwSize: cardinal;
  multiboot_hdr: TMultiboot_hdr;
  image_base, image_size: integer;
  size: cardinal;
  entry_addr: integer;
  LExePath, LParams: string;

begin
  image_base := $00400000;
  entry_addr := integer(@loader) - image_base;
  size := entry_addr - SizeOf(multiboot_hdr);
  image_size := size + $00001000;

  MemoryStream := TMemoryStream.Create;
  fs := TMemoryStream.Create;
  try
    FillChar(multiboot_hdr, SizeOf(multiboot_hdr), 0);
    multiboot_hdr.magic := $1BADB002;
    multiboot_hdr.flags := 1 shl 16;
    multiboot_hdr.checksum :=
      cardinal(-multiboot_hdr.magic - multiboot_hdr.flags);
    multiboot_hdr.header_addr := image_base;
    multiboot_hdr.load_addr := image_base;
    multiboot_hdr.load_end_addr := image_base + image_size;
    multiboot_hdr.bss_end_addr := image_base + image_size;
    multiboot_hdr.entry_addr := image_base + entry_addr;
    multiboot_hdr.mode_type := 0;
    multiboot_hdr.width := 0;
    multiboot_hdr.height := 0;
    multiboot_hdr.depth := 0;

    MemoryStream.WriteBuffer(multiboot_hdr, SizeOf(multiboot_hdr));
    dwSize := entry_addr - SizeOf(multiboot_hdr);
    pBuff := AllocMem(dwSize);
    MemoryStream.WriteBuffer(pBuff^, dwSize);
    FreeMem(pBuff, dwSize);

    pFunc := @loader;
    fwSize := cardinal(@loader_end) - cardinal(@loader);

    dwSize := $00001000 - fwSize;

    pBuff := AllocMem(dwSize);
    MemoryStream.WriteBuffer(pFunc^, fwSize);
    MemoryStream.WriteBuffer(pBuff^, dwSize);
    FreeMem(pBuff, dwSize);

    fs.LoadFromFile('hankaku.bin');
    fs.Position := 0;
    MemoryStream.CopyFrom(fs, 0);

    MemoryStream.SaveToFile('Kernel.bin');
  finally
    MemoryStream.Free;
    fs.Free;
  end;
  LExePath := 'qemu-system-x86_64.exe';
  LParams := '-kernel Kernel.bin';
  ShellExecute(0, nil, PChar(LExePath), PChar(LParams), nil, 5);

end.
