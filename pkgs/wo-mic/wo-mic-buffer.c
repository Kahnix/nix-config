#define _GNU_SOURCE
#include <alsa/asoundlib.h>
#include <dlfcn.h>
#include <errno.h>
#include <pthread.h>

/* WO Mic 4.6 writes 960 frames every 20 ms, but leaves start_threshold at
 * one frame. At the next timer tick the queue can already be empty. Its
 * underrun recovery drops that packet, locking playback into 20 ms of
 * sound followed by 20 ms of silence. Queue three periods before starting
 * so playback has two periods of scheduling headroom. This library is
 * loaded only inside the WO Mic launcher, not into the audio server.
 */
static int (*original_hw_params)(snd_pcm_t *, snd_pcm_hw_params_t *);
static pthread_once_t resolve_once = PTHREAD_ONCE_INIT;

static void resolve_hw_params(void)
{
    original_hw_params = dlsym(RTLD_NEXT, "snd_pcm_hw_params");
}

int snd_pcm_hw_params(snd_pcm_t *pcm, snd_pcm_hw_params_t *params)
{
    int err = pthread_once(&resolve_once, resolve_hw_params);
    if (err != 0)
        return -err;
    if (original_hw_params == NULL)
        return -ENOSYS;

    err = original_hw_params(pcm, params);
    if (err < 0 || snd_pcm_stream(pcm) != SND_PCM_STREAM_PLAYBACK)
        return err;

    snd_pcm_uframes_t period, buffer;
    err = snd_pcm_hw_params_get_period_size(params, &period, NULL);
    if (err < 0)
        return err;
    err = snd_pcm_hw_params_get_buffer_size(params, &buffer);
    if (err < 0)
        return err;

    snd_pcm_sw_params_t *sw;
    snd_pcm_sw_params_alloca(&sw);
    err = snd_pcm_sw_params_current(pcm, sw);
    if (err < 0)
        return err;

    /* Clamp before multiplication; ALSA buffers need not hold three periods. */
    snd_pcm_uframes_t threshold = period > buffer / 3 ? buffer : 3 * period;
    err = snd_pcm_sw_params_set_start_threshold(pcm, sw, threshold);
    if (err < 0)
        return err;
    return snd_pcm_sw_params(pcm, sw);
}
