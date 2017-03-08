%%====================================================================
%%
%% LeoFS Gateway
%%
%% Copyright (c) 2012-2015 Rakuten, Inc.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------
%% LeoFS Gateway - RPC Handler Test
%% @doc
%% @end
%%====================================================================
-module(leo_nfs_readdir_state_ets_server_tests).

-include("leo_gateway.hrl").
-include_lib("eunit/include/eunit.hrl").
-include_lib("leo_logger/include/leo_logger.hrl").

-define(TEST_COOKIE,    <<1,2,3,4,5,6,7,8>>).
-define(TEST_COOKIE_2,  <<8,7,6,5,4,3,2,1>>).
-define(TEST_COOKIE_3,  <<1,1,1,1,1,1,1,1>>).

%%--------------------------------------------------------------------
%% TEST
%%--------------------------------------------------------------------
-ifdef(EUNIT).
readdir_test_() ->
    {foreach, fun setup/0, fun teardown/1,
     [{timeout, 30, fun readdir_entry_and_delete/0},
      {timeout, 30, fun readdir_entry_and_clean/0}]}.

readdir_sync_clean_test_() ->
    {setup, fun setup_zero_thres/0, fun teardown/1,
     [fun readdir_entry_add_clean/0]}.

readdir_sync_mem_thres_test_() ->
    {setup, fun setup_mem_thres/0, fun teardown/1,
     [fun readdir_entry_mem_thres/0]}.

get_count() ->
    Info = leo_nfs_readdir_state_ets_server:info(),
    proplists:get_value('size', Info).

setup() ->
    ok = leo_logger_client_message:new("./", ?LOG_LEVEL_INFO),
    ok = leo_logger_client_base:new(?LOG_GROUP_ID_ACCESS, ?LOG_ID_ACCESS,
                                    "./", ?LOG_FILENAME_ACCESS),
    leo_nfs_readdir_state_ets_server:start_link(
      [{nfsd_readdir_scan_int, 3},
       {nfsd_readdir_entry_ttl, 10}]),
    ok.

setup_mem_thres() ->
    leo_nfs_readdir_state_ets_server:start_link(
      [{nfsd_readdir_scan_int, 180},
       {nfsd_readdir_entry_ttl, 0},
       {nfsd_readdir_mem_thres, 320}]),
    ok.

setup_zero_thres() ->
    leo_nfs_readdir_state_ets_server:start_link(
      [{nfsd_readdir_scan_int, 180},
       {nfsd_readdir_entry_ttl, 0},
       {nfsd_readdir_mem_thres, 0}]),
    ok.

teardown(_) ->
    leo_nfs_readdir_state_ets_server:stop().

readdir_entry_and_delete() ->
    leo_nfs_readdir_state_ets_server:add_readdir_entry(?TEST_COOKIE, dummy),
    Cnt_1 = get_count(),
    ?assertEqual(1, Cnt_1),
    Ret = leo_nfs_readdir_state_ets_server:get_readdir_entry(?TEST_COOKIE),
    ?assertMatch({ok, _}, Ret),
    leo_nfs_readdir_state_ets_server:del_readdir_entry(?TEST_COOKIE),
    Cnt_2 = get_count(),
    ?assertEqual(0, Cnt_2),
    ok.

readdir_entry_and_clean() ->
    leo_nfs_readdir_state_ets_server:add_readdir_entry(?TEST_COOKIE, dummy),
    Cnt_1 = get_count(),
    ?assertEqual(1, Cnt_1),
    timer:sleep(5000),
    Cnt_2 = get_count(),
    ?assertEqual(1, Cnt_2),
    timer:sleep(10000),
    Cnt_3 = get_count(),
    ?assertEqual(0, Cnt_3),
    ok.

readdir_entry_add_clean() ->
    leo_nfs_readdir_state_ets_server:add_readdir_entry(?TEST_COOKIE, dummy),
    Cnt_1 = get_count(),
    ?assertEqual(1, Cnt_1),
    timer:sleep(1000),
    leo_nfs_readdir_state_ets_server:add_readdir_entry(?TEST_COOKIE_2, dummy),
    Cnt_2 = get_count(),
    ?assertEqual(1, Cnt_2),
    leo_nfs_readdir_state_ets_server:del_readdir_entry(?TEST_COOKIE_2),
    Cnt_3 = get_count(),
    ?assertEqual(0, Cnt_3),
    ok.

readdir_entry_mem_thres() ->
    leo_nfs_readdir_state_ets_server:add_readdir_entry(?TEST_COOKIE, dummy),
    Cnt_1 = get_count(),
    ?assertEqual(1, Cnt_1),
    leo_nfs_readdir_state_ets_server:add_readdir_entry(?TEST_COOKIE_2, dummy2),
    Cnt_2 = get_count(),
    ?assertEqual(2, Cnt_2),
    leo_nfs_readdir_state_ets_server:add_readdir_entry(?TEST_COOKIE_3, dummy3),
    Cnt_3 = get_count(),
    ?assertEqual(1, Cnt_3),
    ok.

-endif.
