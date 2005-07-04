#include "\dev\fmk\fakt\fakt.ch"


/*! \fn EnterDim()
 *  \brief Unos dimenzija
 */
function EnterDim()
*{
private GetList:={}
Box( ,5 ,60)
	@ 1+m_x, 2+m_y SAY "Unos dimenzija stakla:"
	@ 3+m_x, 2+m_y SAY "DIM.A" GET _dima VALID !Empty(_dima)
	@ 3+m_x, 25+m_y SAY "x DIM.B" GET _dimb VALID !Empty(_dimb)
	@ 5+m_x, 2+m_y SAY "Broj komada:" GET _kom VALID !Empty(_kom)
	read
BoxC()
return
*}


/*! \fn CalcDim(nDim)
 *  \brief Preracunaj dimenziju u metre
 *  \param nDim - dimenzija
 */
function CalcDim(nDim)
*{
// preracunaj dimenziju iz cm u m
nRet := nDim / 100
return nRet
*}



/*! \fn FillZMatrix()
 *  \brief Filuje inicijalnu matricu zaokruzenja
 */
function FillZMatrix()
*{
local aArr := {}
// puni init matricu sa zaokruzenjima
for i:=21 to 240 step 3
	AADD(aArr, i)
next

return aArr
*}


/*! \fn FindZK(nValue)
 *  \brief Pronadji zaokruzenje
 *  \param nValue - vrijednost koja se trazi
 */
function FindZK(nValue) 
*{
local aArr := {}

if (nValue < 21)
	// ako je vrijednost manja od 21
	return -99
endif

if (nValue > 270)
	// ako je vrijednost veca od 270
	return -999
endif

// napuni matricu zaokruzenja
aArr := FillZMatrix()
// skeniraj vrijednost
nRes := ASCAN(aArr, nValue)
if (nRes == 0)
	nValue := INT(nValue)
	while .t.
		++ nValue
		nRes := ASCAN(aArr, nValue)
		if nRes > 0
			exit
		endif
	enddo
	nRet := aArr[nRes]
else
	if (nValue == 270)
		nRet := aArr[nRes]
	else
		nRet := aArr[nRes + 1]
	endif
endif
return nRet
*}


/*! \fn CalcM2(nDim1, nDim2)
 *  \brief Izracunaj kvadraturu stakla sa dimenz.unesenim u cm
 *  \param nDim1 - dimenzija A u cm
 *  \param nDim2 - dimenzija B u cm
 */
function CalcM2(nDim1, nDim2)
*{
// izracunaj kvadraturu prema dimenzijama u cm
nD1:=CalcDim(nDim1)
nD2:=CalcDim(nDim2)
nRet := nD1 * nD2
return nRet
*}

