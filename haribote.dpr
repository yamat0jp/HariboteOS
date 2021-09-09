program haribote;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.Classes,
  ShellAPI;

{$I asmhead}

procedure harimain; stdcall; forward;
procedure inthandler21(esp: integer); stdcall; forward;

procedure loader; stdcall;
asm
  cli
  call harimain
  hlt
end;

{$I naskfunc}
{$I graph}
{$I bootpack}

procedure harimain; stdcall;
var
  vram: PByte;
  xsize, ysize: integer;
  info: ^TBootInfo;
begin
  info := Pointer($0FF0);
  vram := info^.vram;
  xsize := info^.scrnx;
  ysize := info^.scrny;
  init_gdtidt;
  init_pic;

  init_palette;
  init_screen8(vram, xsize, ysize);
  while True do
    io_hlt;
end;

procedure loader_end; stdcall;
begin

end;

var
  MemoryStream, fs: TMemoryStream;
  pFunc, pBuff: Pointer;
  fwSize, dwSize: cardinal;
  info: ^TBootInfo;
  image_base, image_size: integer;
  LExePath, LParams: string;

begin
  image_base := $c200;
  image_size:=integer(@loader)-image_base;

  MemoryStream := TMemoryStream.Create;
  fs := TMemoryStream.Create;
  try
    info:=Pointer($0ff0);
//    MemoryStream.WriteBuffer(Pointer(image_base)^, image_size);

    MemoryStream.WriteBuffer(info, SizeOf(TBootInfo));
    dwSize := image_size - SizeOf(TBootInfo);
    pBuff := AllocMem(dwSize);
    MemoryStream.WriteBuffer(pBuff^, dwSize);
    FreeMem(pBuff, dwSize);

    pFunc := @loader;
    fwSize := cardinal(@loader_end) - cardinal(@loader);

    image_size := $00001000;
    dwSize := -fwSize + image_size;

    pBuff := AllocMem(dwSize);
    MemoryStream.WriteBuffer(pFunc^, fwSize);
    MemoryStream.WriteBuffer(pBuff^, dwSize);
    FreeMem(pBuff, dwSize);

    if @info.hankaku = nil then
      info.hankaku := Pointer(image_base + MemoryStream.size * SizeOf(Byte));
    fs.LoadFromFile('hankaku.bin');
    MemoryStream.CopyFrom(fs, 0);

    MemoryStream.SaveToFile('Kernel.bin');
  finally
    MemoryStream.Free;
    fs.Free;
  end;
  LExePath := 'qemu-system-i386.exe';
  LParams := '-kernel Kernel.bin';
  ShellExecute(0, nil, PChar(LExePath), PChar(LParams), nil, 5);

end.
