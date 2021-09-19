program Project1;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils, IniFiles;

function load: integer; external 'OSClasses';
function load_end: integer; external 'OSClasses';

var
  i, j: integer;
  ini: TIniFile;

begin
  i := load div 8;
  j := load_end div 8;
  Writeln(i.ToHexString, '/', j.ToHexString);
  Writeln(j - i);
  ini := TIniFile.Create('.\data.ini');
  ini.WriteInteger('address', 'start', i);
  ini.WriteInteger('address', 'size', j - i);
  ini.Free;
  Readln;

end.
