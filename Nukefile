(set @nu_files (filelist "^nu/.*nu$"))
(set @frameworks  '("Nu"))

(set @framework "Nucco")
(set @framework_identifier "com.insect-labs.Nucco")
(set @resource_files (filelist "^resources/.*$"))

(compilation-tasks)
(framework-tasks)

(task "default" => "framework")

(task "install" => "framework" is
    (SH "ditto #{@framework_dir} /Library/Frameworks/#{@framework_dir}")
    (SH "ditto tools/* /usr/local/bin"))

(task "clobber" => "clean" is
      (system "rm -rf #{@framework_dir}"))
