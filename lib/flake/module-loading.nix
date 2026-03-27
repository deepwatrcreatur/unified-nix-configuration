{ lib }:

let
  readEntries = dir: builtins.readDir dir;

  mkPathList = dir: entries:
    lib.mapAttrsToList (name: _: dir + "/${name}") entries;

  filterEntries =
    {
      dir,
      includeDirectories ? true,
      includeFiles ? true,
      blacklist ? [ ],
      whitelist ? null,
      filePredicate ? (_name: true),
      directoryPredicate ? (_name: true),
    }:
    lib.filterAttrs (
      name: type:
      let
        allowedByList =
          if whitelist == null then
            !lib.elem name blacklist
          else
            lib.elem name whitelist;
      in
      allowedByList
      && (
        (includeFiles && type == "regular" && lib.hasSuffix ".nix" name && filePredicate name)
        || (includeDirectories && type == "directory" && directoryPredicate name)
      )
    ) (readEntries dir);
in
{
  mkAutoImport =
    {
      dir,
      blacklist ? [ ],
      whitelist ? null,
      includeDirectories ? true,
      includeFiles ? true,
      filePredicate ? (_name: true),
      directoryPredicate ? (_name: true),
    }:
    mkPathList dir (
      filterEntries {
        inherit dir blacklist whitelist includeDirectories includeFiles filePredicate directoryPredicate;
      }
    );

  mkAutoImportWithBlacklist =
    {
      dir,
      blacklist ? [ ],
      includeDirectories ? true,
      includeFiles ? true,
      filePredicate ? (_name: true),
      directoryPredicate ? (_name: true),
    }:
    mkPathList dir (
      filterEntries {
        inherit dir blacklist includeDirectories includeFiles filePredicate directoryPredicate;
      }
    );

  mkAutoImportFilesOnly =
    {
      dir,
      blacklist ? [ ],
      whitelist ? null,
      filePredicate ? (_name: true),
    }:
    mkPathList dir (
      filterEntries {
        inherit dir blacklist whitelist filePredicate;
        includeDirectories = false;
      }
    );

  mkAutoImportDirsOnly =
    {
      dir,
      blacklist ? [ ],
      whitelist ? null,
      directoryPredicate ? (_name: true),
    }:
    mkPathList dir (
      filterEntries {
        inherit dir blacklist whitelist directoryPredicate;
        includeFiles = false;
      }
    );
}
