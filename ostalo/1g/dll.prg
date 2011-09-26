/* 
 * This file is part of the bring.out FMK, a free and open source 
 * accounting software suite,
 * Copyright (c) 1996-2011 by bring.out doo Sarajevo.
 * It is licensed to you under the Common Public Attribution License
 * version 1.0, the full text of which (including FMK specific Exhibits)
 * is available in the file LICENSE_CPAL_bring.out_FMK.md located at the 
 * root directory of this source code archive.
 * By using this software, you agree to be bound by its terms.
 */



dllname:="t:\sigma\ncom.dll"
funname:="MANAGER"
funres:=0
libhan = BLILIBLOD (dllname)            // Dynamically load the DLL

if libhan > 32                         // If it loaded successfully

//          ******************         // EITHER (most efficient and controlled)

   funhan = BLIFUNHAN (libhan,funname)  // Get the function handle
   if funhan <> 0                      // If the function was found

                                       // Call function with (multiple) params
      funres = BLIFUNCAL (funhan)
                                       // Note that function handle is LAST
   else
      ? "DLL file", dllnme, "does not contain function", funname
      ?
   endif

//          ******************         // OR (easiest but less efficient)

//    funres = &funnme (funpa1,funpa2) // Gives a runtime error if not found
                                       // But also works even if the function
                                       // Was not exported !!

//          ******************         // END

   //? "Function", funnme, "returned", funres // Display the results
   ?

   BLILIBFRE (libhan)                  // Free the library when finished

else
   ? "DLL file ", dllnme, "not found or failed to load"
   ?
endif
