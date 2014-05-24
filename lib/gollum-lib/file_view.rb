# ~*~ encoding: utf-8 ~*~
module Gollum
=begin
  FileView requires that:
    - All files in root dir are processed first
    - Then all the folders are sorted and processed
=end
  class FileView
    # common use cases:
    # set pages to wiki.pages and show_all to false
    # set pages to wiki.pages + wiki.files and show_all to true
    def initialize pages, options = {}
      @pages    = pages
      @show_all = options[:show_all] || false
      @checked  = options[:collapse_tree] ? '' : "checked"
    end

    def enclose_tree string
      %Q(<ol class="tree">\n) + string + %Q(</ol>)
    end

    def new_page page
      name = page.name
      url  = url_for_page page
      %Q(  <li class="file"><a href="#{url}"><span class="icon"></span>#{name}</a></li>)
    end

    def new_folder folder_path
      new_sub_folder folder_path
    end

    def new_sub_folder path
      <<-HTML
      <li>
        <label>#{path}</label> <input type="checkbox" #{@checked} />
        <ol>
      HTML
    end

    def end_folder
      "</ol></li>\n"
    end

    def url_for_page page
      url = ''
      if @show_all
        # Remove ext for valid pages.
        filename = page.filename
        filename = Page::valid_page_name?(filename) ? filename.chomp(::File.extname(filename)) : filename

        url = ::File.join(::File.dirname(page.path), filename)
      else
        url = ::File.join(::File.dirname(page.path), page.filename_stripped)
      end
      url = url[2..-1] if url[0, 2] == './'
      url
    end

    def render_files
      html         = ''

      # keep track of folder depth, 0 = at root.
      prev_folders = ['.']

      # process rest of folders
      @pages.each do |page|
        path   = page.path
        folder = ::File.dirname path

        current_folders = folder.split '/'
        max_depth = [prev_folders.size, current_folders.size].max - 1
        (0..max_depth).each do |depth|
          next if prev_folders[depth] == current_folders[depth]

          if prev_folders[depth].nil?
            (max_depth - depth + 1).times do |index|
              html += new_sub_folder current_folders[depth + index]
            end
            break
          end

          if current_folders[depth].nil?
            (max_depth - depth + 1).times do
              html += end_folder
            end
            break
          end

          if prev_folders[depth] != '.'
            (prev_folders.size - depth).times do
              html += end_folder
            end
          end
          if current_folders[depth] != '.'
            (current_folders.size - depth).times do |index|
              html += new_sub_folder current_folders[depth + index]
            end
          end
          break
        end

        html         += new_page page
        prev_folders  = current_folders
      end

      # return the completed html
      enclose_tree html
    end # end render_files
  end # end FileView class
end # end Gollum module
