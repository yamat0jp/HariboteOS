program Project1;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  classes;

type
  TBootInfo = packed record
    cyls: Int16;
    leds: Int8;
    vmode, scrnx, scrny: Int16;
    vram, hankaku: Pointer;
  end;

var
  ms: tmemorystream;
  info: tbootinfo;
  vram: PByte;
  i: integer;
begin
  try
    { TODO -oUser -cConsole メイン : ここにコードを記述してください }
    ms:=tmemorystream.Create;
    ms.LoadFromFile('kernel.bin');
    ms.ReadBuffer(info,sizeof(tbootinfo));
    ms.Free;
    vram:=Pointer($a0000);
    for i := 0 to $ffff do
      vram[i]:=i and $0f;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
