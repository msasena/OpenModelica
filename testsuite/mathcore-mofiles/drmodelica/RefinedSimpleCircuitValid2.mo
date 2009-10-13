// name:     RefinedSimpleCircuitValid2
// keywords: <insert keywords here>
// status:   correct
// 
// A formal class parameter, can also be a type, which is useful for 
// changing the type of many objects. For example, by providing a type 
// parameter ResistorModel in the class below it is easy to change the 
// resistor type of all objects of type ResistorModel, e.g. from the default 
// type Resistor to the temperature dependent type TempResistor.
// 

  type ElectricPotential = Real (final quantity="ElectricPotential", final unit
        ="V");
  type Voltage = ElectricPotential;
  type ElectricCurrent = Real (final quantity="ElectricCurrent", final unit="A");
  type Current = ElectricCurrent;
  type Capacitance = Real (
      final quantity="Capacitance", 
      final unit="F", 
      min=0);  
  type Inductance = Real (
      final quantity="Inductance", 
      final unit="H", 
      min=0);
 

  // From Modelica.Electrical.Analog.Interfaces
  connector Pin 
    Voltage v;
    flow Current i;
  end Pin;
  
  model Resistor "Electrical resistor" 
    Pin p;
    Pin n "positive and negative pins";
    Voltage v;
    Current i;
    parameter Real R(unit="Ohm") "Resistance";
  equation 
    v = i*R;
  end Resistor;

  partial class TwoPin 
    "Superclass of elements with two electrical pins" 
    Pin p;
    Pin n;
    Voltage v;
    Current i;
  equation 
    v = p.v - n.v;
    p.i + n.i = 0;
    i = p.i;
  end TwoPin;
  
model ResistorCircuit // Circuit of three Resistors connected at one node
  Resistor R1(R = 100);
  Resistor R2(R = 200);
  Resistor R3(R = 300);
equation
  connect(R1.p, R2.p);
  connect(R1.p, R3.p);
end ResistorCircuit;

model GenericResistorCircuit2
  replaceable model ResistorModel = Resistor;
  replaceable Resistor R1(R = 100);		
  replaceable Resistor R2(R = 200);		
  replaceable Resistor R3(R = 300);		
equation
  connect(R1.p, R2.p);
  connect(R1.p, R3.p);
end GenericResistorCircuit2;

model TempResistor
  extends Resistor;
  Real Temp;
  Real RT;
end TempResistor;

model RefinedResistorCircuit2 = 
  GenericResistorCircuit2(redeclare model ResistorModel = TempResistor);

//- The model RefinedResistorCircuit2 should give the same flattened model
//  as the following model (this is the model used to generate the known answer)
//
// model RefinedResistorCircuit2Expanded
//   TempResistor R1(R=100);
//  TempResistor R2(R=200);
//  TempResistor R3(R=300);
// equation
//  connect(R1.p, R2.p);
//  connect(R1.p, R3.p);
// end RefinedResistorCircuit2Expanded;

// fclass RefinedResistorCircuit2Expanded
// Real R1.p.v;
// Real R1.p.i;
// Real R1.n.v;
// Real R1.n.i;
// Real R1.v;
// Real R1.i;
// parameter Real R1.R = 100 "Resistance";
// Real R1.Temp;
// Real R1.RT;
// Real R2.p.v;
// Real R2.p.i;
// Real R2.n.v;
// Real R2.n.i;
// Real R2.v;
// Real R2.i;
// parameter Real R2.R = 200 "Resistance";
// Real R2.Temp;
// Real R2.RT;
// Real R3.p.v;
// Real R3.p.i;
// Real R3.n.v;
// Real R3.n.i;
// Real R3.v;
// Real R3.i;
// parameter Real R3.R = 300 "Resistance";
// Real R3.Temp;
// Real R3.RT;
// equation
//   R1.v = R1.i * R1.R;
//   R2.v = R2.i * R2.R;
//   R3.v = R3.i * R3.R;
//   R1.p.i + R2.p.i + R3.p.i = 0.0;
//   R1.p.v = R2.p.v;
//   R2.p.v = R3.p.v;
//   R1.n.i = 0.0;
//   R2.n.i = 0.0;
//   R3.n.i = 0.0;
// end RefinedResistorCircuit2Expanded;
