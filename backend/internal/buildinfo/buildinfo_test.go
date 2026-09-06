package buildinfo

import (
	"runtime/debug"
	"testing"
)

func TestResolve(t *testing.T) {
	t.Parallel()
	rev := func(revision, modified string) []debug.BuildSetting {
		return []debug.BuildSetting{
			{Key: "vcs.revision", Value: revision},
			{Key: "vcs.modified", Value: modified},
		}
	}
	tests := []struct {
		name     string
		stamped  string
		settings []debug.BuildSetting
		want     string
	}{
		{"the linker stamp wins", "v1.2.3", rev("abcdef1234567890", "false"), "v1.2.3"},
		{"stamp without any build info", "edge-a88415b", nil, "edge-a88415b"},
		{"clean checkout falls back to the revision", "", rev("abcdef1234567890", "false"), "abcdef1"},
		{"a dirty tree is marked", "", rev("abcdef1234567890", "true"), "abcdef1-dirty"},
		{"a short revision is kept whole", "", rev("abcdef1", "false"), "abcdef1"},
		{"nothing to go on", "", nil, "dev"},
		{"build info without a revision", "", []debug.BuildSetting{{Key: "GOOS", Value: "linux"}}, "dev"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			if got := resolve(tt.stamped, tt.settings); got != tt.want {
				t.Errorf("resolve() = %q, want %q", got, tt.want)
			}
		})
	}
}

// Whatever the build, clients must get something to display.
func TestVersionIsNeverEmpty(t *testing.T) {
	t.Parallel()
	if Version() == "" {
		t.Fatal("Version() is empty")
	}
}
