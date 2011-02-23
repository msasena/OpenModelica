#include "stdafx.h"
#include "AlgLoopSolverFactory.h"
#include <boost/extension/shared_library.hpp>
#include <boost/extension/convenience.hpp>

AlgLoopSolverFactory::AlgLoopSolverFactory()
{
}

AlgLoopSolverFactory::~AlgLoopSolverFactory()
{

}

/// Creates a solver according to given system of equations of type algebraic loop
IAlgLoopSolver* AlgLoopSolverFactory::createAlgLoopSolver(IAlgLoop* algLoop)
{
	if(algLoop->getDimVars(IAlgLoop::REAL) > 0)
	{
		type_map types;
		if(!load_single_library(types, "Newton.dll"))
			throw std::invalid_argument(" Newton library could not be loaded");
		std::map<std::string, factory<IAlgLoopSolver,IAlgLoop*, INewtonSettings*> >::iterator iter;
		std::map<std::string, factory<IAlgLoopSolver,IAlgLoop*, INewtonSettings*> >& Newtonfactory(types.get());
		std::map<std::string, factory<INewtonSettings> >::iterator iter2;
		std::map<std::string, factory<INewtonSettings> >& Newtonsettingsfactory(types.get());
		iter2 = Newtonsettingsfactory.find("NewtonSettings");
		if (iter2 ==Newtonsettingsfactory.end()) 
		{
			throw std::invalid_argument("No such Newton Settings");
		}
		_algsolversettings= boost::shared_ptr<INewtonSettings>(iter2->second.create());
		//Todo load or configure settings
		//_algsolversettings->load("config/Newtonsettings.xml");
		iter = Newtonfactory.find("Newton");
		if (iter ==Newtonfactory.end()) 
		{
			throw std::invalid_argument("No such Newton Solver");
		}

		_algsolver= boost::shared_ptr<IAlgLoopSolver>(iter->second.create(algLoop,_algsolversettings.get()));
		return _algsolver.get();
	}
	else
	{
		// TODO: Throw an error message here.
		return 0;
	}
}