require 'yaml'
require 'fileutils'
require 'tmpdir'
require 'digest'
require 'thor/group'

module Middleman
  class Generator < ::Thor::Group
    include ::Thor::Actions

    class_option 'template',
                 aliases: '-T',
                 default: 'middleman/middleman-templates-default',
                 desc: 'Use a project template'

    source_root __dir__


    def detect_if_first_time_install
      @first_time = option_set?('FIRST_TIME') || !File.exist?('config.rb')
    end

    def clone_existing_version
      return if @first_time
      template = YAML.load_file('.template_version')
      dir = Dir.mktmpdir
      files = {}
      
      begin
        run("git clone #{template[:remote]} #{dir}")
        inside(dir) do
          run("git reset --hard #{template[:revision]}")

          inside('template') do
            Dir.glob('**/*', File::FNM_DOTMATCH).reject { |f| File.directory?(f) }.each do |f|
              files[f] = Digest::MD5.file(f).hexdigest
            end
          end
        end
      ensure
        FileUtils.remove_entry(dir)
      end

      files.each do |filename, template_hash|
        local_hash = Digest::MD5.file(filename).hexdigest

        if template_hash == local_hash
          remove_file(filename)
        else
          puts "Keeping #{filename}, local changes made vs template"
        end
      end
    end

    def copy_template_files
      directory 'template', '.', exclude_pattern: /\.DS_Store$/
    end

    def ask_about_paas
      return unless @first_time

      if option_set?('USE_PAAS')
        @use_paas = parse_boolean('USE_PAAS')
      else
        @use_paas = yes?('Will you be deploying this on Government PaaS?')
      end

      return unless @use_paas

      @application_name = ENV['APPLICATION_NAME'] || ask(
        <<-MESSAGE
What is the name of your application on PaaS?
If your application URL is larry-the-cat.cloudapps.digital, this will be "larry-the-cat".
        MESSAGE
      )
    end

    def ask_about_canonical_host
      return unless @first_time

      @canonical_host = ENV['CANONICAL_HOST'] || ask(
        <<-MESSAGE
What is the canonical hostname of your application?
e.g. docs.larry-the-cat.service.gov.uk
        MESSAGE
      )
    end

    def configure_paas
      return unless @first_time
      return unless @use_paas

      template 'optional/manifest.yml', 'manifest.yml'
      copy_file 'optional/nginx.conf', 'nginx.conf'
      gsub_file 'nginx.conf', '__CANONICAL_HOST__', @canonical_host
      directory 'optional/script', 'script'
    end

    def configure_tech_docs
      return unless @first_time

      template 'optional/config/tech-docs.yml', 'config/tech-docs.yml'
    end

    def copy_example_documentation
      return unless @first_time

      directory 'optional/source', 'source'
      copy_file 'optional/README.md', 'README.md'
    end

    def save_version_file
      remote = nil
      revision = nil

      inside(__dir__) do
        remote = run('git remote get-url origin', capture: true).strip
        revision = run('git rev-parse head', capture: true).strip
      end

      raise 'Unable to get remote / revision' unless remote && revision

      remove_file '.template_version'
      create_file '.template_version', { remote: remote, revision: revision }.to_yaml
    end

  private

    def option_set?(key)
      ENV.key?(key)
    end

    def parse_boolean(key)
      ENV[key] == 'true'
    end
  end
end
