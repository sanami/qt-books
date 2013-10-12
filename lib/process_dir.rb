require 'find'

##
# Пройтись по каталогу
def process_dir(dir_path, action, &gui_proc)
  puts "process_dir #{dir_path}"
  dir_count = 0
  Dir.glob("#{File.expand_path(dir_path)}/**/*") do |file_path|
    case action
      when :count
        # Считать кол-во каталогов
        if FileTest.directory? file_path
          dir_count += 1
          gui_proc.call(:count, file_path) if gui_proc
        end
      when :list
        if FileTest.directory? file_path
          # Прогресс
          gui_proc.call(:list, file_path)
        else
          gui_proc.call(:action, file_path)
        end
    end
  end

  # Возвращаемое значение
  case action
    when :count
      dir_count
    else
      nil
  end
end
