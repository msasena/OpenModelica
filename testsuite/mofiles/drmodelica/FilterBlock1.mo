// name:     FilterBlock1
// keywords: initial, reinit
// status:   correct
// 
// First order filter block
// Drmodelica: 9.1 reinit (p. 296)
//

block FilterBlock1 
  parameter Real T = 1 "Time constant";
  parameter Real k = 1 "Gain";
  input Real u = 1;
  output Real y;
protected
  Real x;
equation
  der(x) = (u - x)/T;
  y = k*x;
algorithm
  when initial() then
    reinit(x, u); // if x is u since der(x) = (u - x)/T
  end when;
end FilterBlock1;

// Result:
// class FilterBlock1
//   parameter Real T = 1.0 "Time constant";
//   parameter Real k = 1.0 "Gain";
//   input Real u = 1.0;
//   output Real y;
//   protected Real x;
// equation
//   der(x) = (u - x) / T;
//   y = k * x;
// algorithm
//   when initial() then
//     reinit(x, u);
//   end when;
// end FilterBlock1;
// endResult
