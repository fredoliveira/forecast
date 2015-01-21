require 'rubygems'
require 'appscript'
require 'colorize'

include Appscript

class OmniFocus
  def initialize
    @omnifocus = Appscript.app('OmniFocus').default_document
  end

  # Recursive method to get the subtask tree from a given task object
  def all_subtasks task
    [task] + task.tasks.get.flatten.map{|t| all_subtasks(t) }
  end

  def all_tasks
    # This doesn't work reliably and for some reason returns stale content.
    # Someone who's better at OF's applescript than me can probably refactor.
    # omnifocus.flattened_projects[its.status.eq(:active)].tasks.get.flatten

    # So we go at it the hard way:
    @omnifocus.flattened_projects.tasks.get.flatten.map{|t| all_subtasks(t) }.flatten
  end

  # Returns an array of tasks with a due date set to the future
  def due_tasks
    tasks = []

    all_tasks.each do |task|
      due = task.due_date.get

      if due.is_a?(Time) && due > Time.new
        tasks << Task.new(task.name.get, due)
      end
    end

    # Sorts the array of tasks by due_date
    tasks.sort! { |a,b| a.due_date <=> b.due_date }
  end
end

class Task
  attr_reader :title
  attr_reader :due_date

  def initialize(title, due_date)
    @title = title
    @due_date = due_date
  end
end

class Forecast
  def initialize
    @omnifocus = OmniFocus.new
    @days = @omnifocus.due_tasks.group_by(&:due_date)
  end

  def render
    @days.each do |date, tasks|
      puts "\n>>> #{date.strftime('%d %B %Y')}\n".colorize(:light_blue)

      for task in tasks
        puts "* #{task.title}"
      end
    end
  end
end

Forecast.new.render
