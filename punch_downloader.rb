#!/usr/bin/env ruby
#
# Put this script in your PATH and download from punchmangas.com.br like this:
#   punch_downloader.rb Bleach [chapter number]
#
# You will find the downloaded chapters under $HOME/Documents/PunchManga/Bleach
#
# If you run this script without arguments, it will check your local manga downloads
# and check if there are any new chapters
#
# This scripts was base on script made by Fábio Akita www.akitaonrails.com.br
#
# Create by Maykon Luís Capellari
# E-mail: maykon_capellari@yahoo.com.br

require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'open-uri'

manga_root = "http://www.punchmangas.com.br/"
manga_download_folder = File.join(ENV['HOME'],"/Documents/PunchManga/")
agent = Mechanize.new { |agent| agent.follow_meta_refresh = true }

if ARGV.size == 0
 # no args means just to check for new chapters
 mangas = Dir.glob(File.join(manga_download_folder, "*")).map do |f| 
   f.gsub(manga_download_folder, '').downcase
 end
 mangas.each do |manga_name|
   downloaded_chapters = Dir.glob(File.join(manga_download_folder, manga_name, "*")).map do |f|
     f.gsub(File.join(manga_download_folder, manga_name, "/"), "").to_i
   end.sort
   last_chapter = downloaded_chapters.last
   
   #index page
   puts manga_root + "listagem/" + manga_name
   agent.get(manga_root + "listagem/" + manga_name)
   
   chapters = agent.page.links.map {|l| $1.to_i if l.href =~ /#{manga_name}\/(\d+)/ }.compact.sort
   most_recent_chapter = chapters.last
   puts "Last Chapter: #{last_chapter}/Most Recent: #{most_recent_chapter} - #{manga_name}"   
 end
 exit 0
end

manga_name = ARGV.first.downcase || "bleach"
start_from_chapter = ARGV.size > 1 ? ARGV[1] : nil

manga_folder = File.join(manga_download_folder, manga_name)

#create folder if no exist
unless File.exist? manga_folder
  puts "Creating #{manga_folder}"
  FileUtils.mkdir_p(manga_folder)
end

# index page
agent.get(manga_root + "listagem/" + manga_name)

chapter_link = agent.page.links.select do |l|
  if start_from_chapter
    l.href =~ /#{manga_name}\/#{start_from_chapter}\//
  else  
    l.href =~ /#{manga_name}\/\d+/
  end
end.reverse.first.href

chapter_number = nil
chapter_folder = ""

link = /http:\/\/img1.punchmangas.com.br\/mangas\/(\d+)\/(\d+)_(\d+)\//

ncap = nil
begin  
  #chapter_link = cap.options[ncap].value unless ncap.nil? || cap.nil? || ncap < 0
  
  chapter_page = agent.get :url => chapter_link, :referer => agent.page
  
  form = chapter_page.form("cont")
  cap = form.field_with(:name => 'capitulos')
  opt = cap.option_with(:selected => true)
  ncap = cap.options.find_index opt
  
  puts "############################################################################################"
  puts "Chapter: #{opt.text}"
  puts "Chapter Link: #{chapter_link}"
  
  # create the chapter folder if it changes
  current_chapter_number = chapter_page.uri.to_s.split("/")[-2] # /[manga]/[chapter]/[page]
  page = chapter_page.uri.to_s.split("/")[-1].match(/\d+/).to_s
  
  if chapter_number != current_chapter_number
    chapter_number = current_chapter_number
    chapter_number = "0#{chapter_number}" if chapter_number.to_i < 10
    chapter_folder = File.join(manga_download_folder, manga_name, chapter_number)
    unless File.exist? chapter_folder
      puts "Creating #{chapter_folder}"
      FileUtils.mkdir_p(chapter_folder)
    end
  end
  
  npage = form.field_with(:name => 'paginas')
  index = npage.option_with(:selected => true).value.to_i  
  page = index
  
  while page <= npage.options.nitems
    # download image file    
    img_uri = agent.page.search("//script")[3].text.gsub(link).first
    page = "0#{page}" if page.to_i < 10
    img_uri << "#{page}.jpg"
    image_file = File.join(chapter_folder, img_uri.split("/").last)
    open(image_file, 'wb') do |file|
      puts "Downloading #{img_uri} to #{image_file}"
      file.write(open(img_uri).read)
    end    
    
    page = page.to_i + 1
    new_page = agent.page.uri.to_s.gsub(/#\d+/, "##{page}")    
    agent.get :url => new_page, :referer => agent.page
  end
  ncap = ncap - 1
  chapter_link = cap.options[ncap].value unless ncap < 0
end until ncap < 0