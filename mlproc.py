# -*- coding: utf-8 -*-

"""
Wrapper class for Matlab processes


__________________________________________________________________________
Copyright (C) 2016-2017 OpenNFT.org

Written by Evgeny Prilepin

"""

import time
import multiprocessing as mp

import matlab.engine as me

import config


# ==============================================================================
def _start_matlab(event: mp.Event,
                  alive_check_period=60, startup_options=None, shared_name=None):
    pid = mp.current_process().pid

    print('Start matlab process %s with process ID {}'.format(pid) % shared_name )

    event.clear()

    if startup_options is None:
        eng = me.start_matlab()
    else:
        eng = me.start_matlab(startup_options)

    try:
        if shared_name:
            eng.matlab.engine.shareEngine(shared_name, nargout=0)
        else:
            eng.matlab.engine.shareEngine(nargout=0)
            shared_name = eng.matlab.engine.engineName(nargout=1)

        print('Matlab shared engine {} is started'.format(shared_name))
    except me.MatlabExecutionError:
        raise
    finally:
        event.set()

    while True:
        # Is matlab alive?
        try:
            eng.version(nargout=0)
        except me.EngineError:
            break
        time.sleep(alive_check_period)

    # Delete '_matlab' key to supress error if matlab has been terminated
    del eng.__dict__["_matlab"]

    print('Terminate matlab helper process %s with process ID {}'.format(pid) % shared_name )


# ==============================================================================
class MatlabSharedEngineHelper(object):
    """A helper class for using shared matlab engine sessions
    """

    # --------------------------------------------------------------------------
    def __init__(self, alive_check_period=60, startup_options=None, shared_name=None):
        self._engine = None

        self._alive_check_period = alive_check_period  # second
        self._startup_options = startup_options
        self._shared_name = shared_name
        self._name = ''

    # --------------------------------------------------------------------------
    @property
    def engine(self):
        return self._engine

    # --------------------------------------------------------------------------
    @property
    def name(self):
        return self._name

    # --------------------------------------------------------------------------
    def connect(self, start=True, name_prefix=None):
        """Connects to a shared matlab session
        """
        if self.engine is not None:
            return True

        if not self._connect(name_prefix):
            if start:
                self._start()
                return self._connect(name_prefix)
            else:
                return False
        else:
            return True

    # --------------------------------------------------------------------------
    def prepare(self):
        """Prepares Matlab session for needs of NFB
        """
        if not self.engine:
            return

        self.engine.cd(config.MATLAB_FUNCTIONS_PATH)
        self.engine.addMatlabDirs(nargout=0)
        self.engine.clear('all', nargout=0)

    # --------------------------------------------------------------------------
    def destroy_engine(self):
        if self._engine:
            del self._engine.__dict__["_matlab"]
            del self._engine
        self._engine = None

    # --------------------------------------------------------------------------
    def _connect(self, name_prefix=None):
        sessions = me.find_matlab()

        if not sessions:
            return

        if not name_prefix:
            name = sessions[0]
        else:
            name = ''
            for s in sessions:
                if s.startswith(name_prefix):
                    name = s
                    break
            if not name:
                return False

        try:
            print('Connecting to Matlab shared engine {}'.format(name))
            self._engine = me.connect_matlab(name)
            print('Connected to Matlab shared engine {}'.format(name))
        except me.EngineError:
            return False

        self._name = name
        return True

    # --------------------------------------------------------------------------
    def _start(self):
        e = mp.Event()

        p = mp.Process(
            target=_start_matlab,
            args=(e, self._alive_check_period,
                  self._startup_options, self._shared_name))

        p.daemon = False
        p.start()
        e.wait()
