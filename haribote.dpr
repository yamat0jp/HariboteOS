program haribote;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.Classes,
  ShellAPI,
  IniFiles,
  asmhead;

var
  MemoryStream, fs: TMemoryStream;
  image_size, size: cardinal;
  image_base, start, entry: integer;
  multiboot_hdr: TMultiBoot_hdr;
  ini: TIniFile;
  LExePath, LParams: string;

begin
  MemoryStream := TMemoryStream.Create;
  fs := TMemoryStream.Create;
  ini := TIniFile.Create('.\data.ini');
  try
    fs.LoadFromFile('OSClasses.dll');
    image_base := $100;
    start := ini.ReadInteger('address', 'start', 0);
    entry := start - image_base;
    image_size := SizeOf(TMultiBoot_hdr) + fs.size + $00001000;
    multiboot_hdr.magic := $1BADB002;
    multiboot_hdr.flags := 0;
    multiboot_hdr.checksum :=
      cardinal(-multiboot_hdr.magic - multiboot_hdr.flags);
    multiboot_hdr.header_addr := image_base;
    multiboot_hdr.load_addr := image_base;
    multiboot_hdr.load_end_addr := cardinal(image_base) + image_size;
    multiboot_hdr.bss_end_addr := cardinal(image_base) + image_size;
    multiboot_hdr.entry_addr := start;
    multiboot_hdr.mode_type := 0;
    multiboot_hdr.width := 360;
    multiboot_hdr.height := 280;
    multiboot_hdr.depth := 0;
    multiboot_hdr.screen_addr := Pointer($B8000);

    MemoryStream.WriteBuffer(multiboot_hdr, SizeOf(multiboot_hdr));
    MemoryStream.CopyFrom(fs, 0);
    MemoryStream.SaveToFile('Kernel.bin');
  finally
    MemoryStream.Free;
    fs.Free;
    ini.Free;
  end;
  LExePath := 'qemu-system-x86_64.exe';
  LParams := '-kernel Kernel.bin';
  ShellExecute(0, nil, pchar(LExePath), pchar(LParams), nil, 5);

end.
