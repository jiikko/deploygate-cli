module DeployGate
  class CommandBuilder
    include Commander::Methods
    attr_reader :arguments

    def run
      GithubIssueRequest::Url.config('deploygate', 'deploygate-cli')

      program :name, 'dg'
      program :version,  VERSION
      program :description, 'You can control to DeployGate in your terminal.'

      command :init do |c|
        c.syntax = 'dg init'
        c.description = 'project initial command'
        c.action do |args, options|
          begin
            Commands::Init.run
          rescue => e
            error_handling("Commands::Init Error: #{e.class}", create_error_issue_body(e), ['bug', 'Init'])
            raise e
          end
        end
      end

      command :deploy do |c|
        c.syntax = 'dg deploy /path/to/app'
        c.description = 'upload to deploygate'
        c.option '--message STRING', String, 'release message'
        c.option '--user STRING', String, 'owner name or group name'
        c.option '--open', 'open browser (OSX only)'
        c.option '--disable_notify', 'disable notify via email (iOS app only)'
        c.action do |args, options|
          options.default :message => '', :user => nil, :open => false, 'disable_notify' => false
          begin
            Commands::Deploy.run(args, options)
          rescue => e
            error_handling("Commands::Deploy Error: #{e.class}", create_error_issue_body(e), ['bug', 'Deploy'])
            raise e
          end
        end
      end
      alias_command :'push', :deploy

      command :logout do |c|
        c.syntax = 'dg logout'
        c.description = 'logout'
        c.action do |args, options|
          begin
            Commands::Logout.run
          rescue => e
            error_handling("Commands::Logout Error: #{e.class}", create_error_issue_body(e), ['bug', 'Logout'])
            raise e
          end
        end
      end

      run!
    end

    # @param [Exception] error
    # @return [String]
    def create_error_issue_body(error)
      return <<EOF
# Error message
#{error.message}

# Backtrace
```
#{error.backtrace.join("\n")}
```
EOF
    end

    # @param [String] title
    # @param [String] body
    # @param [Array] labels
    def error_handling(title, body, labels)
      options = {
          :title => title,
          :body  => body,
          :labels => labels.push("v#{DeployGate::VERSION}")
      }
      url = GithubIssueRequest::Url.new(options).to_s
      puts ''
      if HighLine.agree('Do you want to report this issue on GitHub? (y/n) ') {|q| q.default = "n"}
        puts "Please open github issue: #{url}"
        system('open', url) if Commands::Deploy::Push.openable?
      end
      puts ''
    end
  end
end
