module Harvest
  module API
    class Projects < Base
      api_model Harvest::Project
      
      include Harvest::Behavior::Crud
      
     # Retrieves all projects
     #
     # Overriding #all defined in Harvest::Behavior::Crud since Harvest::NotFound is returned for
     # @return [Array<Harvest::Project>] an array of Projects
     def all(user = nil, query_options = {})
       query = query_options.merge!(of_user_query(user))
       begin
         response = request(:get, credentials, "/projects", :query => query)
         Harvest::Project.parse(response.parsed_response)
       rescue Harvest::NotFound
         response = request(:get, credentials, "/daily", :query => query)
         Harvest::Project.non_admin_parse(response.parsed_response)
       end
     end

      # Creates and Assigns a task to the project
      #
      # == Examples
      #  project = harvest.projects.find(401)
      #  harvest.projects.create_task(project, 'Bottling Glue') # creates and assigns a task to the project
      #
      # @return [Harvest::Project]
      def create_task(project, task_name)
        response = request(:post, credentials, "/projects/#{project.to_i}/task_assignments/add_with_create_new_task", :body => {"task" => {"name" => task_name}}.to_json)
        id = response.headers["location"].match(/\/.*\/(\d+)\/.*\/(\d+)/)[1]
        find(id)
      end
      
      # Deactivates the project. Does nothing if the project is already deactivated
      # 
      # @param [Harvest::Project] project the project you want to deactivate
      # @return [Harvest::Project] the deactivated project
      def deactivate(project)
        if project.active?
          request(:put, credentials, "#{api_model.api_path}/#{project.to_i}/toggle", :headers => {'Content-Length' => '0'})
          project.active = false
        end
        project
      end
      
      # Activates the project. Does nothing if the project is already activated
      # 
      # @param [Harvest::Project] project the project you want to activate
      # @return [Harvest::Project] the activated project
      def activate(project)
        if !project.active?
          request(:put, credentials, "#{api_model.api_path}/#{project.to_i}/toggle", :headers => {'Content-Length' => '0'})
          project.active = true
        end
        project
      end
    end
  end
end