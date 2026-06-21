#! /bin/sh
#
# test-backend-configs.sh
#
# Validates MulleUIOS backend config switching by building and running
# the test suite under each config. Run from the MulleUIOS project root.
#
# Usage:
#   ./test-backend-configs.sh [glfw|sdl|sdl-d3d11|all]
#
# Requires: mulle-sde, wine (for windows platform tests)
#

CONFIGS="${1:-all}"
PASS=0
FAIL=0
ORIGINAL_CONFIG=""

fail()
{
   echo "FAIL: $*" >&2
   FAIL=$(( FAIL + 1 ))
}

pass()
{
   echo "PASS: $*"
   PASS=$(( PASS + 1 ))
}

run_config()
{
   local config="$1"
   local platforms="${2:-linux}"

   echo ""
   echo "=== Config: $config (platforms: $platforms) ==="

   mulle-sde config switch "${config}" || true

   # tell the test subproject which MulleUIOS config to use, then re-fetch
   # so the stash reflection is updated
   ( cd test && mulle-sde env set MULLE_SOURCETREE_CONFIG_NAME_MULLE_UIOS "${config}" \
             && mulle-sde fetch > /dev/null 2>&1 ) || true
   mulle-sde test clean all > /dev/null 2>&1 || true

   # verify config actually switched
   local actual
   actual="$(mulle-sde config switch -p 2>/dev/null)"
   if [ "${actual}" != "${config}" ]; then
      fail "${config}: config switch failed (got '${actual}')"
      return
   fi

   # verify sourcetree has expected deps by reading the config file
   local configfile=".mulle/etc/sourcetree/${config}"
   case "${config}" in
      glfw)
         grep -q "MulleGLFW"      "${configfile}" || { fail "${config}: MulleGLFW missing from config";       return; }
         grep -q "MulleCGNanovgGL" "${configfile}" || { fail "${config}: MulleCGNanovgGL missing from config"; return; }
         grep -q "MulleSDL"       "${configfile}" && { fail "${config}: MulleSDL should not be in config";    return; }
         pass "${config}: sourcetree correct"
      ;;
      sdl)
         grep -q "MulleSDL"       "${configfile}" || { fail "${config}: MulleSDL missing from config";        return; }
         grep -q "MulleCGNanovgGL" "${configfile}" || { fail "${config}: MulleCGNanovgGL missing from config"; return; }
         grep -q "MulleGLFW"      "${configfile}" && { fail "${config}: MulleGLFW should not be in config";   return; }
         pass "${config}: sourcetree correct"
      ;;
      sdl-d3d11)
         grep -q "MulleSDL"       "${configfile}" || { fail "${config}: MulleSDL missing from config";        return; }
         grep -q "MulleCGNanovg"  "${configfile}" || { fail "${config}: MulleCGNanovg missing from config";   return; }
         grep -q "MulleCGNanovgGL" "${configfile}" && { fail "${config}: MulleCGNanovgGL should not be in sdl-d3d11"; return; }
         grep -q "MulleCGNanovg-craftinfo" "${configfile}" || { fail "${config}: craftinfo missing from config"; return; }
         [ -f "craftinfo/MulleCGNanovg-craftinfo.d3d11/definition/set/MULLE_CG_BACKEND" ] \
            && grep -q "D3D11" "craftinfo/MulleCGNanovg-craftinfo.d3d11/definition/set/MULLE_CG_BACKEND" \
            || { fail "${config}: MULLE_CG_BACKEND definition file missing or wrong"; return; }
         pass "${config}: sourcetree correct (craftinfo present, MULLE_CG_BACKEND=D3D11)"
         # compile check only — no Wine D3D11 runtime
         mulle-sde test --platform linux craft > /tmp/test-${config}-linux.log 2>&1 \
            && pass "${config}: linux compile OK" \
            || { fail "${config}: linux compile FAILED (see /tmp/test-${config}-linux.log)"; return; }
         return 0
      ;;
   esac

   # craft + run for each platform
   for platform in ${platforms}; do
      local log="/tmp/test-${config}-${platform}.log"

      mulle-sde test --platform "${platform}" craft > "${log}" 2>&1 \
         && pass "${config}/${platform}: craft OK" \
         || { fail "${config}/${platform}: craft FAILED (see ${log})"; continue; }
      mulle-sde test --platform "${platform}" run >> "${log}" 2>&1 \
         && pass "${config}/${platform}: tests OK" \
         || fail "${config}/${platform}: tests FAILED (see ${log})"
   done
}

check_error_config()
{
   echo ""
   echo "=== Config: config (should error) ==="
   mulle-sde config switch config 2>/dev/null || true
   # fetch will fail with the error message — that's the expected behavior
   if mulle-sde fetch 2>&1 | grep -qi "choose one of"; then
      pass "config: error message correct"
   else
      fail "config: expected error message not found"
   fi
   # switch back to glfw so subsequent steps work
   mulle-sde config switch glfw > /dev/null 2>&1 || true
}

# Save current config to restore at end
ORIGINAL_CONFIG="$(mulle-sde config switch -p 2>/dev/null || echo glfw)"

case "${CONFIGS}" in
   all)
      check_error_config
      run_config glfw   "linux windows"
      run_config sdl    "linux windows"
      run_config sdl-d3d11 "linux"
   ;;
   glfw|sdl)
      run_config "${CONFIGS}" "linux windows"
   ;;
   sdl-d3d11)
      run_config sdl-d3d11 "linux"
   ;;
   config)
      check_error_config
   ;;
   *)
      echo "Unknown config: ${CONFIGS}" >&2
      exit 1
   ;;
esac

# Restore original config
echo ""
echo "=== Restoring config: ${ORIGINAL_CONFIG} ==="
mulle-sde config switch "${ORIGINAL_CONFIG}" > /dev/null 2>&1 || true
( cd test && mulle-sde env set MULLE_SOURCETREE_CONFIG_NAME_MULLE_UIOS "${ORIGINAL_CONFIG}" ) > /dev/null 2>&1 || true

echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="
[ "${FAIL}" -eq 0 ]
