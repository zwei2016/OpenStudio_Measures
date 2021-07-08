# insert your copyright here

# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/reference/measure_writing_guide/


require 'csv'

# start the measure
class OutputCSV < OpenStudio::Measure::ReportingMeasure
  # human readable name
  def name
    # Measure name should be the title case of the class name.
    return 'OutputCSV'
  end

  # human readable description
  def description
    return 'Output to CSV'
  end

  # human readable description of modeling approach
  def modeler_description
    return 'Output to CSV'
  end

  # define the arguments that the user will input
  def arguments(model = nil)
    args = OpenStudio::Measure::OSArgumentVector.new
	
    variable_name = OpenStudio::Measure::OSArgument.makeStringArgument("variable_name",true)
    variable_name.setDisplayName("Enter Variable Name.")
	variable_name.setDefaultValue("Zone Air Temperature")
    args << variable_name
	
	key_name = OpenStudio::Measure::OSArgument.makeStringArgument("key_name",true)
    key_name.setDisplayName("Enter Key Value Name.")
	key_name.setDefaultValue("THERMAL ZONE LAB")
    args << key_name
	
	reporting_frequency_chs = OpenStudio::StringVector.new
    reporting_frequency_chs << "Hourly"
    reporting_frequency_chs << "Zone Timestep"
    reporting_frequency = OpenStudio::Measure::OSArgument.makeChoiceArgument('reporting_frequency', reporting_frequency_chs, true)
    reporting_frequency.setDisplayName("Reporting Frequency.")
    reporting_frequency.setDefaultValue("Zone Timestep")
    args << reporting_frequency 
	
    file_path = OpenStudio::Measure::OSArgument.makeStringArgument("file_path", true)
    file_path.setDisplayName("Enter the path to the file that contains reference value:")
    file_path.setDescription("Example: 'C:\\Projects\\values.csv'")
	file_path.setDefaultValue("C:\\Users\\CGBC012\\Documents\\HZmodel\\MeasurementData\\lab.csv")
    args << file_path

    return args
  end

  # define what happens when the measure is run
  def run(runner, user_arguments)
    super(runner, user_arguments)
    # use the built-in error checking (need model)
    if !runner.validateUserArguments(arguments, user_arguments)
      return false
    end
	
    # get the last model and sql file
    model = runner.lastOpenStudioModel
    if model.empty?
      runner.registerError('Cannot find last model.')
      return false
    end
    model = model.get



    # get measure arguments
    variable_name = runner.getStringArgumentValue("variable_name",user_arguments)
	key_name = runner.getStringArgumentValue("key_name",user_arguments)
    reporting_frequency = runner.getStringArgumentValue("reporting_frequency",user_arguments) 
	file_path = runner.getStringArgumentValue("file_path", user_arguments)
	
    # load sql file
    sql_file = runner.lastEnergyPlusSqlFile
    if sql_file.empty?
      runner.registerError('Cannot find last sql file.')
      return false
    end
    sql_file = sql_file.get
    model.setSqlFile(sql_file)

    # get the weather file run period (as opposed to design day run period)
    ann_env_pd = nil
    sql_file.availableEnvPeriods.each do |env_pd|
      env_type = sql_file.environmentType(env_pd)
      if env_type.is_initialized
        if env_type.get == OpenStudio::EnvironmentType.new('WeatherRunPeriod')
          ann_env_pd = env_pd
          break
        end
      end
    end
	
	if ann_env_pd
	   output_timeseries = sql_file.timeSeries(ann_env_pd, reporting_frequency, variable_name, key_name)
	   
	   if output_timeseries.empty?
	      runner.registerWarning('Timeseries not found.')
	   else
	      runner.registerInfo('Found timeseries.')
		  output_timeseries = output_timeseries.get.values
       end
	end
	#runner.registerInfo("output_timeseries is good #{output_timeseries.to_a}")
	
	#######################################
    # check file path for reasonableness
    if file_path.empty?
      runner.registerError('Empty file path was entered.')
      return false
    end

    # strip out the potential leading and trailing quotes
    file_path.gsub!('"', '')

    # check if file exists
    if !File.exist? file_path
      runner.registerError("The file at path #{file_path} doesn't exist.")
      return false
    end  

    # read in csv values
    csv_values = CSV.read(file_path,{headers: false, converters: :float})
    num_rows = csv_values.length
	
	runner.registerInfo("The reference file has been imported with #{num_rows} items.")
	#####################################
	
	#calculate the error term	  
	csv_array = []
	csv_array << output_timeseries.to_a
	num_elem = output_timeseries.length
	runner.registerInfo("The simulated data contains #{num_elem} items.")
	
	csv_values_to_compare = csv_values.last(num_elem)
	#runner.registerInfo("I am fine here, with #{csv_values_to_compare.length}")
	finalArray = output_timeseries.zip(csv_values_to_compare).map{|x,y| (x - y[0])**2}
	#finalArray = output_timeseries.zip(csv_values_to_compare)
	#runner.registerInfo("I am fine here 2: #{finalArray}")
	indicator = Math.sqrt((finalArray.reduce(:+))/num_elem)
	
	File.open("./report_#{variable_name.delete(' ')}.csv",'wb') do |file|
	   file.puts indicator
	end 
	
	runner.registerInfo("The mean square root between simulated data and measured data is #{indicator}")
	
	#########################
	

    File.open("./report_#{variable_name.delete(' ')}_#{reporting_frequency.delete(' ')}.csv", 'wb') do |file|
       csv_array.each do |elem|
       #file.puts elem.join(',')
	   file.puts elem
       end
    end	   
	runner.registerInfo("The data is storded in ./report_#{variable_name.delete(' ')}_#{reporting_frequency.delete(' ')}.csv")	

    # close the sql file
    sql_file.close

    return true
  end
end

# register the measure to be used by the application
OutputCSV.new.registerWithApplication
