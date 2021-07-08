# insert your copyright here
# Wei Zhang 
# OpenStudio Application v1.1.0
# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# This measure change the openstuio::model::ConstructionWithInternalSource 

# start the measure
class TABSSlabThermal < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'TABS Slab Thermal'
  end

  # human readable description
  def description
    return 'Change the thermal behavior of Construction with Internal Source '
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Change the thermal behavior of Construction with Internal Source '
  end

  def check_multiplier(runner, multiplier)
    if multiplier < 0
      runner.registerError("Multiplier #{multiplier} cannot be negative.")
      false
    end
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

	# make an argument insulation R-value
    r_value_mult = OpenStudio::Measure::OSArgument.makeDoubleArgument('r_value_mult', true)
    r_value_mult.setDisplayName('Slab total R-value multiplier')
    r_value_mult.setDefaultValue(1)
    args << r_value_mult

    thermal_mass_mult = OpenStudio::Measure::OSArgument.makeDoubleArgument('thermal_mass_mult', true)
    thermal_mass_mult.setDisplayName('Slab thermal mass multiplier')
    thermal_mass_mult.setDefaultValue(1)
    args << thermal_mass_mult

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)



    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables : input from GUI
    r_value_mult = runner.getDoubleArgumentValue('r_value_mult', user_arguments)
    check_multiplier(runner, r_value_mult)

    thermal_mass_mult = runner.getDoubleArgumentValue('thermal_mass_mult', user_arguments)
    check_multiplier(runner, thermal_mass_mult)
	
	# parse openstuio::model::ConstructionWithInternalSource and deal with each construction
	model.getConstructionWithInternalSources.each do |construction|
	   # fetch all the layers in a construction 	   
	   layers = construction.layers
	   # parse each layer with index
	   layers.each_with_index do |layer, l_index|
	     runner.registerInfo("Name: #{layer.name}")
		 runner.registerInfo("Handle: #{layer.handle.to_s}")
		 
	     runner.registerInfo("Original Thermal Resistance: #{layer.to_OpaqueMaterial.get.thermalResistance}")
		 runner.registerInfo("Original Density: #{layer.to_StandardOpaqueMaterial.get.density}")
		 #runner.registerInfo("Solar absorptance #{layer.to_StandardOpaqueMaterial.get.solarAbsorptance}")
		 ro_t = layer.to_OpaqueMaterial.get.thermalResistance
		 ro_d = layer.to_StandardOpaqueMaterial.get.density
		 
		 # copy and conversion 
		 new_layer = layer.clone
         new_layer = new_layer.to_Material.get
		 
		 # set the thermal parameters and layer name
		 new_layer.to_OpaqueMaterial.get.setThermalResistance(ro_t*r_value_mult)
		 new_layer.to_StandardOpaqueMaterial.get.setDensity(ro_d*thermal_mass_mult)
		 new_layer.setName("#{layer.name} (R:#{r_value_mult},D:#{thermal_mass_mult})")
		 
		 # update construction with new layers
		 construction.setLayer(l_index, new_layer)
		 runner.registerInfo("Updated Layer Name: #{new_layer.name}")
		 runner.registerInfo("Updated Thermal Resistance: #{new_layer.to_OpaqueMaterial.get.thermalResistance}")
		 runner.registerInfo("Updated Density: #{new_layer.to_StandardOpaqueMaterial.get.density}")
	   end 
	   runner.registerInfo("The modified construction is: #{construction}")
	end	



    return true
  end
end

# register the measure to be used by the application
TABSSlabThermal.new.registerWithApplication
