# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/

# start the measure
class DeleteNondrawnFace < OpenStudio::Measure::ModelMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'Delete nondrawn face'
  end

  # human readable description
  def description
    return 'Delete a specified face safely'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Delete a specified face safely'
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Measure::OSArgumentVector.new

    # the name of the space to add to the model
    surface_name = OpenStudio::Measure::OSArgument.makeStringArgument('surface_name', true)
    surface_name.setDisplayName('Surface name to delete')
    surface_name.setDescription('This surface will be deleted from the geometry.')
	surface_name.setDefaultValue('Face 216')
    args << surface_name

    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    # assign the user inputs to variables
    surface_name = runner.getStringArgumentValue('surface_name', user_arguments)

    # check the space_name for reasonableness
    if surface_name.empty?
      runner.registerError('Empty space name was entered.')
      return false
    end
	
	surfaces = model.getSurfaces
	surface_delete = ''
	# report initial condition of model
    runner.registerInitialCondition("The building started with #{surfaces.size} surfaces.")
	
	surfaces.each do |surface|
	  
	  if surface.name.get.match(surface_name.to_s)
	     #surface.remove()
		 surface_delete = surface.name
		 runner.registerInfo("we found #{surface.name}.")
		 surface.remove()
	  
	  end
	end 


    # echo the new space's name back to the user
    runner.registerInfo("Surface #{surface_delete} was removed.")

    # report final condition of model
    runner.registerFinalCondition("The building finished with #{model.getSurfaces.size} surfaces.")

    return true
  end
end

# register the measure to be used by the application
DeleteNondrawnFace.new.registerWithApplication
