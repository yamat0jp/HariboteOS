program Project1;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  classes, asmhead;

var
  ms, sc: tmemorystream;
  size: integer;
  hdr: TMultiboot_hdr;

begin
  try
    { TODO -oUser -cConsole メイン : ここにコードを記述してください }
    ms := tmemorystream.Create;
    ms.LoadFromFile('kernel.bin');
    ms.Position := 0;
    ms.ReadBuffer(hdr, SizeOf(hdr));
    Writeln(integer(hdr.screen_addr).ToHexString);
    Writeln(hdr.width,'/',hdr.height);
    Readln;
    ms.Free;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
