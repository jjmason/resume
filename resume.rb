#!/usr/bin/env ruby
# encoding: utf-8

require "yaml"
require "prawn"
require "prawn/measurement_extensions"
module Resume
  class Data
    def initialize(hash)
      hash.each_pair {|k,v| instance_variable_set "@#{k}",v}
    end
  end

  class Me < Data
    attr_reader :name, :email,:phone,:objective, :skills, :jobs, :school
    def initialize(hash)
      super hash
      @jobs = jobs.map {|job| Job.new job}
    end
  end

  class Job < Data
    attr_reader :title, :employer, :period, :description, :bullets
  end


  class PDF < Prawn::Document

    def initialize(me)
      super :margin => 0.75.in
      @me = me
    end


    def render _
      #pdf.font "fonts/Rufina-Regular.ttf"
      font "Helvetica"
      puts @me,@me.name
      #Save position
      y1 = cursor

      # Name
      text @me.name, :size => 34

      # Contact info on the right
      move_cursor_to y1
      text @me.email, :align => :right
      text @me.phone, :align => :right

      move_down 10
      # Rulex
      stroke_horizontal_rule

      move_down 20

      section "What I want to do" do
         text @me.objective
      end

      section "Where I went to school" do
        text @me.school
      end

      # Skills cloud
      section "Things I know how to do, and how well I know them" do
         render_word_cloud @me.skills
      end

      # Heading for experience
      section "Things I've done" do
        @me.jobs.each {|e| render_job e}
      end

      pad(20) do
        text "This resume is open source: <color rgb='0000FF'><u><a href='http://github.com/jjmason/resume'>github.com/jjmason/resume</a></u></color>",
            :inline_format => true
      end

      super
    end

    def render_job(job)
      # Render split text for basic info
      float do
        text job.period, :align => :right, :style => :bold
      end

        text job.title, :style => :bold
        text job.employer, :style => :bold

      # Back down for description
      text job.description

      # Bullets
      table job.bullets.map {|bullet| ["#{Prawn::Text::NBSP}•#{Prawn::Text::NBSP}", bullet]},
            :column_widths => [10, bounds.width - 10],
            :cell_style => {:borders => [], :padding => [2,0,0,0]}
      move_down 20
    end


    def bullet(text)
      bullet_width = 10
      table([[" • ", text]], :column_widths => [bullet_width, bounds.width - bullet_width], :cell_style => {:borders => [], :padding => [2,0,0,0]})
    end


    def section(heading)
      pad 15 do
        text heading, :align => :left, :style => :bold, :size => 16

        stroke_horizontal_rule
        move_down 10
        yield
        move_down 5
      end
    end

    # Render a word cloud.  Words is a hash of key => weight.
    def render_word_cloud(words, min_size = 11.0, max_size = 18.0,
                                 min_color = 0, max_color = 0x99)
      # Normalize weights as (x - min) / (max - min) so we have a range from 0 to 1
      max = words.values.max
      min = words.values.min
      fact = 1.0 / (max - min).to_f # Error if weights are all the same, but I don't care ;P
      words = words.map {|word,weight| [word, (weight - min) * fact]}

      # Convert the normalized weights to sizes and colors, which we just slosh on into the array.
      # w * (max - min) + min is the formula here, and for colors we want to use 1 - w
      size_fact = (max_size - min_size).to_f
      color_fact = (max_color - min_color).to_f
      words.each do |array|
        array << size_fact * array[1] + min_size
        array << sprintf("%02X",(color_fact * (1 - array[1]) + min_color).to_i)
      end

      # Here's the ugly part, where we glom everything together to make the inline
      # formatted text
      s = ""
      words.shuffle.each do |word, weight, size, color|
        s << "<font size='#{size}'><color rgb='#{color*3}'>#{word}  </color></font>"
      end

      text s,:inline_format => true

    end

  end

  def main
    me = Me.new YAML.load_file("resume.yaml")
    PDF.new(me).render_file("resume.pdf")
  end
  module_function :main
end

if $0 == __FILE__
  Resume.main
end