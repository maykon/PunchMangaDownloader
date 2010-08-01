#!/usr/bin/env ruby
# Generate PDFs for the PunchManga downloaded images
# Use like this:
#   ruby punchmanga_pdf.rb Bleach 5 10 50
#
# Meaning:
#   Manga: Bleach (name of the folder)
#   Number of volumes: 5 (number of generated PDF files)
#   Starting chapter: 10 (default is 0)
#   Last chapter: 50 (default is -1, which is everything)
#
# This scripts was adapted on script made by Fábio Akita www.akitaonrails.com.br
#
# Create by Maykon Luís Capellari
# E-mail: maykon_capellari@yahoo.com.br

require 'rubygems'
require 'enumerator'
require 'prawn'

if ARGV.size < 1
  puts "Pass a manga name.\npunchmanga_pdf.rb manga_name [# volumes] [# start chapter] [# last chapter]"
  exit(1)
end

manga_name    = ARGV[0].downcase
volumes       = ARGV[1].to_i > 0 ? ARGV[1].to_i : 1  # defaults to just one volume

manga_download_folder = File.join(ENV['HOME'],"/Documents/PunchManga/")
manga_current_folder = File.join(manga_download_folder, manga_name)

folders = Dir.glob(File.join(manga_current_folder, "*")) # fetch all chapters
# correctly sort directories names based o the chapter number at the end
folders.sort! do |a, b| 
  a =~ /\/(\d+)$/
  x = $1.to_i
  b =~ /\/(\d+)$/
  y = $1.to_i
  x <=> y
end
#folders = folders[start_chapter..last_chapter] # limit chapters to process
folders = folders.collect {|c| c.match(/\d+/)[0]}

start_chapter = ARGV[2].to_i > 0 ? ARGV[3].to_i : folders.first.to_i
last_chapter  = ARGV[3].to_i > 0 ? ARGV[3].to_i : folders.last.to_i # defaults to all chapters

mangas_folders = []
folders.each do |c|
  if c.to_i >= start_chapter && c.to_i <= last_chapter
    mangas_folders << "#{manga_current_folder}/#{c}"
  end
end

current_volume = 1
mangas_folders.each_slice(volumes) do |chapter_folders|
  manga_file = File.join(manga_download_folder, manga_name + "_#{current_volume}.pdf")
  File.delete(manga_file) if File.exists?(manga_file)

  print "\nPrinting volume #{manga_file} ..."
  Prawn::Document.generate(manga_file, :margin => 0, :page_size => "A4") do
    chapter_folders.each do |chapter|
      Dir.glob(File.join(chapter, "*")).each do |page|
        next if page =~ /credit/
        image page, :fit => [595.28,841.89]
        start_new_page
        print "."
      end
    end
  end
  current_volume += 1
end

puts "Finished printing out #{volumes} volumes for #{manga_name}."
