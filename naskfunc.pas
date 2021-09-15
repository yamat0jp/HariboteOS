procedure io_hlt; stdcall;
asm
  hlt
end;

procedure io_cli; stdcall;
asm
  cli
end;

procedure io_sti; stdcall;
asm
  sti
end;

procedure io_stihlt; stdcall;
asm
  sti
  hlt
end;

function io_in8(port: integer): Int8; stdcall;
asm
  mov dx,  WORD [port]
  in  al, dx
  mov @Result,  al
end;

function io_in16(port: integer): Int16; stdcall;
asm
  mov edx,  port
  mov eax,  0
  in  ax,  dx
end;

function io_in32(port: integer): Int32; stdcall;
asm
  mov edx,  port
  in  eax,  dx
end;

function io_out8(port, data: integer): integer; stdcall;
asm
  mov edx,  port
  mov al,  BYTE [data]
  out dx, al
end;

function io_out16(port, data: integer): Int16; stdcall;
asm
  mov edx,  port
  mov eax,  data
  out dx, ax
end;

function io_out32(port, data: integer): Int32; stdcall;
asm
  mov edx,  port
  mov eax,  data
  out dx, eax
end;

function io_load_eflags: integer; stdcall;
asm{
  pushfd
  pop eax
  ret }
end;

function io_store_eflags(port: integer): integer; stdcall;
asm{
  mov eax,  port
  push  eax
  popfd
  ret }
end;

procedure load_gdtr(limit, addr: integer); stdcall;
asm
  mov eax, limit
  mov addr,  eax
  lgdt  WORD [addr]
end;

procedure load_idtr(limit, addr: integer); stdcall;
asm
  mov eax,  limit
  mov addr,  eax
  lidt  WORD [addr]
end;

procedure asm_inthandler21; stdcall;
asm        {
  push  es
  push  ds
  pushad
  mov eax,  esp
  push  eax
  mov ax, ss
  mov ds, ax
  mov es, ax
  call  inthandler21
  pop eax
  popad
  pop ds
  pop es
  iretd }
end;

procedure asm_inthandler27; stdcall;
asm

end;

procedure asm_inthandler2c; stdcall;
asm

end;
