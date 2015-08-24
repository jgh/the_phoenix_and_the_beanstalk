defmodule Mix.Tasks.Eb.ZipRelease do
  use Mix.Task

  @shortdoc "Creates  a  zip file  in  the  rel director for  upload to  Amazon Elastic Beanstalk"

  @moduledoc """
  Creates  a  zip file  in  the  rel director for  upload to  Amazon Elastic Beanstalk
  Update  .elasticbeanstalk/config.yml
  Add:
deploy:
  artifact: rel/{name}-{version}.zip

  Run
  >MIX_ENV=prod mix do  release, eb.zip_release
  Then deploy with
  >eb  deploy"
  """
  def run(_args) do

    name  =  Mix.Project.config |> Keyword.get(:app) |> Atom.to_string
    version  =  Mix.Project.config |> Keyword.get(:version)
    zipfile =     "#{name}-#{version}.zip"

    target_path =  Path.join(release_dir,  zipfile);

    File.rm(target_path)
    File.cd! release_dir, fn ->
      release_files =
        Path.wildcard("{Dockerfile,Dockerrun.aws.json}") ++
        Path.wildcard("#{name}/{bin,lib,releases}")
      files =  release_files
        |> Enum.map&(String.to_char_list(&1))

      {:ok, _} = :zip.create(String.to_char_list(zipfile),  files)
      Mix.shell.info "Created  #{target_path}"
    end
    :ok
  end


  defp release_dir do
    "rel"
  end


end
