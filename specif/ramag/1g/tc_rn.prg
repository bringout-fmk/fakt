#include "\dev\fmk\fakt\fakt.ch"


function RunRnTC()
*{

altd()
nVal:=26
nRet:=FindZK(nVal)
? "ZK - " + STR(nRet)
if nRet <> 27
	? "TC neuspjesan!"
else
	? "TC uspjesan!"
endif

Sleep(4)

nVal:=129
nRet:=FindZK(nVal)
? "ZK - " + STR(nRet)
if nRet <> 132
	? "TC neuspjesan!"
else
	? "TC uspjesan!"
endif
Sleep(4)

nVal:=82.5
nRet:=FindZK(nVal)
? "ZK - " + STR(nRet)
if nRet <> 84
	? "TC neuspjesan!"
else
	? "TC uspjesan!"
endif

Sleep(4)

cStr:="SYSTEM"
cRet:=""
cRet:=CryptSc(cStr)
? cRet

Sleep(4)


return
*}


