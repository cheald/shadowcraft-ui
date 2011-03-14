function getValueOfDigit(digit, alphabet)
{
   var pos = alphabet.indexOf(digit);
   return pos;
}

function convertBase(src, srcAlphabet, dstAlphabet)
{
   var srcBase = srcAlphabet.length;
   var dstBase = dstAlphabet.length;

   var wet     = src;
   var val     = 0;
   var mlt     = 1;

   while (wet.length > 0)
   {
     var digit  = wet.charAt(wet.length - 1);
     val       += mlt * getValueOfDigit(digit, srcAlphabet);
     wet        = wet.substring(0, wet.length - 1);
     mlt       *= srcBase;
   }

   wet          = val;
   var ret      = "";

   while (wet >= dstBase)
   {
     var digitVal = wet % dstBase;
     var digit    = dstAlphabet.charAt(digitVal);
     ret          = digit + ret;
     wet /= dstBase;
   }

   var digit    = dstAlphabet.charAt(wet);
   ret          = digit + ret;

   return ret;
}