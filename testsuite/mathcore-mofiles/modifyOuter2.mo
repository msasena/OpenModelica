// name:     modifyOuter2
// keywords: modification inner outer innerouter
// status:   correct
// 
//  the most inner modification is the actual
//

connector Pin "Pin of an electrical component"
  flow Real i;
  Real v;
end Pin;

model last
 outer Pin ip;
 Real x;
 equation
  der(x) = ip.v;
end last;

model mid2
 inner outer Pin ip(i=-3,v=-3);
 Real x;
 last la;
 Pin y;
equation
  x = der(x)+ip.v;
  connect(ip,y);
    y.v = 2.4;
end mid2;

model mid1
 inner outer Pin ip(i=13);
 Real x;
 mid2 mid;
equation
  x = der(x)+ip.v;
end mid1;

model inn 
 inner Pin ip(v=23);
 mid1 io;
 equation 
end inn;
// fclass inn
// Real ip.i;
// Real ip.v = 23.0;
// Real io.ip.i = 13.0;
// Real io.ip.v;
// Real io.x;
// Real io.mid.ip.i = -3.0;
// Real io.mid.ip.v = -3.0;
// Real io.mid.x;
// Real io.mid.la.x;
// Real io.mid.y.i;
// Real io.mid.y.v;
// equation
//   der(io.mid.la.x) = io.mid.ip.v;
//   io.mid.x = der(io.mid.x) + io.ip.v;
//   io.mid.y.v = 2.4;
//   io.x = der(io.x) + ip.v;
// io.ip.v = io.mid.y.v;
//   io.ip.i + io.mid.y.i = 0.0;
//   ip.i = 0.0;
// end inn;
