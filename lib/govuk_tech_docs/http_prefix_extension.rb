module GovukTechDocs
  class SassHttpPrefixExtension < Middleman::Extension
    def after_configuration
      app.extensions[:sprockets].environment.context_class.class_eval do
        # Override the `asset-path()` helper available in Sprockets to
        # return a directory rather than a file if the path ends with `/`
        alias_method :orig_asset_path, :asset_path

        def asset_path path, options = {}
          if options.empty? && path.end_with?("/")
            File.join(*[app.config[:http_prefix], path].compact)
          else
            orig_asset_path path, options
          end
        end
      end
    end
  end
end

::Middleman::Extensions.register(:sass_http_prefix, GovukTechDocs::SassHttpPrefixExtension)
