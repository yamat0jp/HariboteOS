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
  TBootInfo = packed record
    cyls, leds, vmode, reserve: Int16;
    scrnx, scrny: Int16;
    vram: Int16;
  end;

  TSegment = packed record
    limit_low, base_low: Int16;
    base_mid, access_right: Int16;
    limit_hight, base_hight: Int16;
  end;

  TGate = packed record
    offset_low, selector: Int16;
    dw_count, access_right: Int16;
    offset_hight: Int16;
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
asm
  mov edx,  [esp+4]
  mov eax,  [esp+8]
  out dx, ax
  ret
end;

function io_out16(port, data: integer): Int16; stdcall;
asm
  mov edx,  [esp+4]
  mov eax,  [esp+8]
  out dx, ax
  ret
end;

function io_out32(port, data: integer): Int32; stdcall;
asm
  mov edx,  [esp+4]
  mov eax,  [esp+8]
  out dx, eax
  ret
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

procedure load_gdtr(limit, addr: integer);
asm
  mov ax, [esp+4]
  mov [esp+6],  ax
  lgdt  [esp+6]
  ret
end;

procedure load_idtr(limit, addr: integer);
asm

end;

procedure set_segmdesc(var sd: TSegment; limit, base, ar: cardinal); stdcall;
begin
  if limit > $FFFFF then
  begin
    ar := ar or $8000;
    limit := limit div $1000;
  end;
  sd.limit_low := limit and $FFFF;
  sd.base_low := base and $FFFF;
  sd.base_mid := (base shr 16) and $FF;
  sd.base_hight := (base shr 24) and $FF;
end;

procedure set_gatedesc(var gd: TGate; offset, selector, ar: cardinal); stdcall;
begin
  gd.offset_low := offset and $FFFF;
  gd.selector := selector;
  gd.dw_count := (ar shr 8) and $FF;
  gd.access_right := ar and $FF;
  gd.offset_hight := (offset shr 16) and $FFFF;
end;

procedure init_gdtidt; stdcall;
var
  gdt: ^TSegment;
  idt: ^TGate;
  i: integer;
begin
  gdt := Pointer($00270000);
  idt := Pointer($0026F800);
  for i := 0 to 8192 do
  begin
    inc(integer(gdt), i);
    set_segmdesc(gdt^, 0, 0, 0);
  end;
  inc(integer(gdt));
  set_segmdesc(gdt^, $FFFFFFFF, $00000000, $4092);
  inc(integer(gdt), 2);
  set_segmdesc(gdt^, $0007FFFF, $00280000, $409A);
  load_gdtr($FFFF, $00270000);
  for i := 0 to 256 do
  begin
    inc(integer(idt), i);
    set_gatedesc(idt^, 0, 0, 0);
  end;
  load_idtr($07FF, $0026F800);
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
  s: PChar); stdcall;
var
  i: integer;
  hankaku: PByte;
begin
  hankaku := $0000;
  i := 0;
  while s[i] <> #0 do
  begin
    putfont8(vram, xsize, x, y, b, hankaku + i * 16);
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

procedure init_screen(vram: PByte; x, y: integer); stdcall;
begin

end;

procedure harimain; stdcall;
var
  i: integer;
  vram: PByte;
  xsize, ysize: integer;
  info: ^TBootInfo;
begin
  info := Pointer($0FF0);
  vram := Pointer(info^.vram);
  xsize := info^.scrnx;
  ysize := info^.scrny;
  {
    for i := 0 to xsize * ysize - 1 do
    begin
    screen[3 * i] := 255;
    screen[3 * i + 1] := 255;
    screen[3 * i + 2] := 255;
    end; }
  init_palette;
  init_screen(vram, xsize, ysize);
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
  info: TBootInfo;
  image_base, image_size: integer;
  size: cardinal;
  entry_addr: integer;
  LExePath, LParams: string;

begin
  image_base := $00400000;
  entry_addr := integer(@loader) - image_base;
  size := entry_addr - SizeOf(TBootInfo);

  MemoryStream := TMemoryStream.Create;
  fs := TMemoryStream.Create;
  try
    FillChar(info, SizeOf(TBootInfo), #0);
    info.scrnx := 320;

    {
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
      multiboot_hdr.depth := 0; }

    MemoryStream.WriteBuffer(info, SizeOf(TBootInfo));
    dwSize := entry_addr - SizeOf(TBootInfo);
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
