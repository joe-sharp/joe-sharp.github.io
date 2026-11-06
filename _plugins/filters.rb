# frozen_string_literal: true

module Stackbit
  # Liquid filters available to the Jekyll templates
  module Filters
    def if(input, if_true, if_false)
      input ? if_true : if_false
    end

    def starts_with(input, str)
      input.start_with?(str)
    end

    def ends_with(input, str)
      input.end_with?(str)
    end

    def link(input)
      relative_path = input.strip

      return relative_path if relative_path.start_with?("#")

      site = @context.registers[:site]

      site.each_site_file do |item|
        return item.url if item.relative_path == relative_path
        # This takes care of the case for static files that have a leading /
        return item.url if item.relative_path == "/#{relative_path}"
      end

      raise ArgumentError, <<~MSG
        Could not find document '#{relative_path}' in 'link' filter.

        Make sure the document exists and the path is correct.
      MSG
    end

    def is_empty(input)
      if input.respond_to?(:empty?)
        input.empty?
      else
        !input
      end
    end

    def is_not_empty(input)
      if input.respond_to?(:empty?)
        !input.empty?
      else
        !!input
      end
    end

    def replace_regexp(input, pattern, replacement)
      regexp = /#{pattern}/
      input.gsub(regexp, replacement)
    end

    def sprintf(format, argument)
      Object.send(:sprintf, format, argument)
    end

    def get_page(page_path)
      site = @context.registers[:site]
      relative_page_path = page_path.sub(/^\//, "")
      relative_page_parts = relative_page_path.split("/")

      if site.collections.key?(relative_page_parts[0])
        find_collection_doc(site, page_path, relative_page_parts)
      else
        site.pages.find { |page| page.relative_path == relative_page_path }
      end
    end

    # rubocop:disable-next Metrics/AbcSize
    def get_pages(folder_path)
      site = @context.registers[:site]

      relative_folder_path = folder_path.sub(/^\//, "").sub(/\/$/, "")
      if relative_folder_path == ""
        relative_folder_path = "."
      end

      relative_folder_parts = relative_folder_path.split("/")

      if site.collections.key?(relative_folder_parts[0])
        if relative_folder_parts.length != 1
          raise ArgumentError, "get_pages can not have sub-folders inside collection folder, received #{folder_path}"
        end

        site.collections[relative_folder_parts[0]].docs
      else
        site.pages.select { |page|
          File.dirname(page.path).sub(/^\//, "").sub(/\/$/, "") == relative_folder_path
        }
      end
    end

    # Returns the next value in the list each time it is called
    class Cycler < Liquid::Drop
      def initialize(values)
        super()
        @values = values
        @counter = 0
      end

      def next
        res = @values[@counter % @values.length]
        @counter += 1
        res
      end
    end

    def cycler(input, delimiter = " ")
      Cycler.new(input.split(delimiter, -1))
    end

    private

    # Private so Liquid does not register these as filters
    def find_collection_doc(site, page_path, parts)
      if parts.length > 2
        raise ArgumentError, "get_page can not have sub-folders inside collection folder, received #{page_path}"
      end

      site.collections[parts[0]].docs.find { |doc| doc_matches_name?(doc, parts[1]) }
    end

    def doc_matches_name?(doc, name)
      if doc.data.key?("slug") && doc.data.key?("ext")
        doc.data["slug"] + doc.data["ext"] == name
      else
        doc.basename == name
      end
    end
  end
end

Liquid::Template.register_filter(Stackbit::Filters)
