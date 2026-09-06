// Package buildinfo reports the release this binary was built from, so the
// instance can tell its clients which build they are talking to.
package buildinfo

import (
	"runtime/debug"
	"sync"
)

// version is stamped at build time:
//
//	go build -ldflags "-X showdown/internal/buildinfo.version=v1.2.3"
//
// The published images set it from the pushed tag, or from the commit on
// main. An unstamped build falls back to its VCS revision.
var version string

// resolve picks the version to report: the stamp the linker left, else the
// revision the toolchain recorded, else "dev".
func resolve(stamped string, settings []debug.BuildSetting) string {
	if stamped != "" {
		return stamped
	}
	var revision string
	var modified bool
	for _, s := range settings {
		switch s.Key {
		case "vcs.revision":
			revision = s.Value
		case "vcs.modified":
			modified = s.Value == "true"
		}
	}
	if revision == "" {
		return "dev"
	}
	if len(revision) > 7 {
		revision = revision[:7]
	}
	if modified {
		return revision + "-dirty"
	}
	return revision
}

var resolved = sync.OnceValue(func() string {
	info, ok := debug.ReadBuildInfo()
	if !ok {
		return resolve(version, nil)
	}
	return resolve(version, info.Settings)
})

// Version is the release tag of this build, the commit it was built from, or
// "dev". It is never empty.
func Version() string { return resolved() }
