# Frozen-string-literal: true
# Copyright: 2015 Forestry.io - MIT License
# Encoding: utf-8

module Jekyll
  class Menus
    autoload :Utils, "jekyll/menus/utils"
    autoload :Drops, "jekyll/menus/drops"

    def initialize(site)
      @site = site
    end

    #

    def menus
      Utils.deep_merge(
        _data_menus, _page_menus
      )
    end

    #

    def to_liquid_drop
      Drops::All.new(
        menus
      )
    end

    #

    def _data_menus
      out = {}

      @site.data["menus"].each do |key, menu|
        if menu.is_a?(Hash) || menu.is_a?(Array)
          (menu = [menu].flatten).each do |item|
            _validate_config_menu_item(
              item
            )
          end

        else
          _throw_invalid_menu_entry(
            menu
          )
        end

        merge = { key => menu }
        merge["_frontmatter"] = false
        out = Utils.deep_merge(
          out, merge
        )
      end

      out
    end

    #

    def _page_menus
      out = {}

      @site.pages.select { |p| p.data.keys.grep(/menus?/).size > 0 }.each_with_object({}) do |page|
        [page.data["menus"], page.data["menu"]].flatten.compact.map do |menu|

          # --
          # menu: key
          # menu:
          #   - key1
          #   - key2
          # --

          if menu.is_a?(Array) || menu.is_a?(String)
            _simple_front_matter_menu(menu, {
              :mergeable => out, :page => page
            })

          #

          elsif menu.is_a?(Hash)
            menu.each do |key, item|
              out[key] ||= []

              # --
              # menu:
              #   key: identifier
              # --

              if item.is_a?(String)
                out[key] << _fill_front_matter_menu({ "identifier" => item }, {
                  :page => page
                })

              # --
              # menu:
              #   key:
              #     url: /url
              # --

              elsif item.is_a?(Hash)
                out[key] << _fill_front_matter_menu(item, {
                  :page => page
                })

              # --
              # menu:
              #   key:
              #     - url: /url
              # --

              else
                _throw_invalid_menu_entry(
                  item
                )
              end
            end

          # --
          # menu:
          #   key: 3
          # --

          else
            _throw_invalid_menu_entry(
              menu
            )
          end
        end
      end

      out
    end

    #

    private
    def _simple_front_matter_menu(menu, mergeable: nil, page: nil)
      if menu.is_a?(Array)
        then menu.each do |item|
          if !item.is_a?(String)
            _throw_invalid_menu_entry(
              item
            )

          else
            _simple_front_matter_menu(item, {
              :mergeable => mergeable, :page => page
            })
          end
        end

      else
        mergeable[menu] ||= []
        mergeable[menu] << _fill_front_matter_menu(nil, {
          :page => page
        })
      end
    end

    #

    private
    def _fill_front_matter_menu(val, page: nil)
      raise ArgumentError, "Kwd 'page' is required." unless page
      val ||= {}

      val["url"] ||= page.url
      val["identifier"] ||= File.basename(page.name, page.ext)
      val["title"] ||= page.data["title"]
      val["_frontmatter"] = page.relative_path # page.url can be changed with permalink frontmatter
      val["weight"] ||= -1
      val
    end

    #

    private
    def _validate_config_menu_item(item)
      if !item.is_a?(Hash) || !item.values_at("url", "title", "identifier").compact.size == 3
        _throw_invalid_menu_entry(
          item
        )
      else
        item["weight"] ||= -1
      end
    end

    #

    private
    def _throw_invalid_menu_entry(data)
      raise RuntimeError, "Invalid menu item given: #{
        data.inspect
      }"
    end
  end
end

require "jekyll/menus/hook"
