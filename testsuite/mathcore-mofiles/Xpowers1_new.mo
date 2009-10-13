// name:     Xpowers1
// keywords: equation,array
// status:   correct
// 
// <decription>
//

model Xpowers1
  parameter Real x = 10;
  Real a = 1;
  parameter Integer n = 5;
  Real xpowers[n];
  Real y;
equation
  xpowers[1] = 1;
  xpowers[2] = xpowers[1]*x;
  xpowers[3] = xpowers[2]*x;
  xpowers[4] = xpowers[3]*x;
  xpowers[4 + 1] = xpowers[4]*x;
  y = a * xpowers[5];
end Xpowers1;

// fclass Xpowers1
// parameter Real x = 10;
// Real a;
// parameter Integer n = 5;
// Real xpowers[1];
// Real xpowers[2];
// Real xpowers[3];
// Real xpowers[4];
// Real xpowers[5];
// Real y;
// equation
//   a = 1.0;
//   xpowers[1] = 1.0;
//   xpowers[2] = xpowers[1] * x;
//   xpowers[3] = xpowers[2] * x;
//   xpowers[4] = xpowers[3] * x;
//   xpowers[5] = xpowers[4] * x;
//   y = a * xpowers[5];
// end Xpowers1;
