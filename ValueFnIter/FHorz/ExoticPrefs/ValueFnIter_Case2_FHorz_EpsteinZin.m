function [V, Policy]=ValueFnIter_Case2_FHorz_EpsteinZin(n_d,n_a,n_z,N_j,d_grid, a_grid, z_grid, pi_z, Phi_aprime, Case2_Type, ReturnFn, Parameters, DiscountFactorParamNames, ReturnFnParamNames, PhiaprimeParamNames, vfoptions)
% DiscountFactorParamNames contains the names for the three parameters relating to
% Epstein-Zin preferences. Calling them beta, gamma, and psi,
% respectively the Epstein-Zin preferences are given by
% U_t= [ (1-beta)*u_t^(1-1/psi) + beta (E[(U_{t+1}^(1-gamma)])^((1-1/psi)/(1-gamma))]^(1/(1-1/psi))
% where
%  u_t is per-period utility function. c_t if just consuption, or ((c_t)^v(1-l_t)^(1-v)) if consumption and leisure (1-l_t)

V=nan;
Policy=nan;

N_d=prod(n_d);
N_a=prod(n_a);
N_z=prod(n_z);

if Case2_Type~=3
    error('Epstein-Zin preferences have only been implemented for Case2_Type=3. Let me know if you need something else')
end

%% Just do the standard case
if Case2_Type==3 % Note: it is not possible with Case2_Type=3 that there is no z variable
    if vfoptions.parallel==2
        if isfield(vfoptions,'n_e')
            if isfield(vfoptions,'e_grid_J')
                e_grid=vfoptions.e_grid_J(:,1); % Just a placeholder
            else
                e_grid=vfoptions.e_grid;
            end
            if isfield(vfoptions,'pi_e_J')
                pi_e=vfoptions.pi_e_J(:,1); % Just a placeholder
            else
                pi_e=vfoptions.pi_e;
            end
            [VKron,PolicyKron]=ValueFnIter_Case2_3_FHorz_EpsteinZin_e_raw(n_d, n_a, n_z, vfoptions.n_e, N_j, d_grid, a_grid, z_grid, e_grid, pi_z, pi_e, Phi_aprime, Case2_Type, ReturnFn, Parameters, DiscountFactorParamNames, ReturnFnParamNames, PhiaprimeParamNames, vfoptions);
        else
            [VKron, PolicyKron]=ValueFnIter_Case2_3_FHorz_EpsteinZin_raw(n_d,n_a,n_z, N_j, d_grid, a_grid, z_grid, pi_z, Phi_aprime, Case2_Type, ReturnFn, Parameters, DiscountFactorParamNames, ReturnFnParamNames, PhiaprimeParamNames, vfoptions);
        end
    elseif vfoptions.parallel==0 || vfoptions.parallel==1
        error('Epstein-Zin currently only implemented for Parallel=2')
    end
end



if vfoptions.outputkron==0
    %Transforming Value Fn and Optimal Policy Indexes matrices back out of Kronecker Form
    if isfield(vfoptions,'n_e')
        if N_z==0
            V=reshape(VKron,[n_a,vfoptions.n_e,N_j]);
            Policy=UnKronPolicyIndexes_Case2_FHorz(PolicyKron, n_d, n_a, vfoptions.n_e, N_j, vfoptions); % Treat e as z (because no z)
        else
            V=reshape(VKron,[n_a,n_z,vfoptions.n_e,N_j]);
            Policy=UnKronPolicyIndexes_Case2_FHorz_e(PolicyKron, n_d, n_a, n_z, vfoptions.n_e, N_j, vfoptions);
        end
    else
        V=reshape(VKron,[n_a,n_z,N_j]);
        Policy=UnKronPolicyIndexes_Case2_FHorz(PolicyKron, n_d, n_a, n_z, N_j, vfoptions);
    end
else
    V=VKron;
    Policy=PolicyKron;
end

% Sometimes numerical rounding errors (of the order of 10^(-16) can mean
% that Policy is not integer valued. The following corrects this by converting to int64 and then
% makes the output back into double as Matlab otherwise cannot use it in
% any arithmetical expressions.
if vfoptions.policy_forceintegertype==1
    fprintf('USING vfoptions to force integer... \n')
    % First, give some output on the size of any changes in Policy as a
    % result of turning the values into integers
    temp=max(max(max(abs(round(Policy)-Policy))));
    while ndims(temp)>1
        temp=max(temp);
    end
    fprintf('  CHECK: Maximum change when rounding values of Policy is %8.6f (if these are not of numerical rounding error size then something is going wrong) \n', temp)
    % Do the actual rounding to integers
    Policy=round(Policy);
    % Somewhat unrelated, but also do a double-check that Policy is now all positive integers
    temp=min(min(min(Policy)));
    while ndims(temp)>1
        temp=min(temp);
    end
    fprintf('  CHECK: Minimum value of Policy is %8.6f (if this is <=0 then something is wrong) \n', temp)
%     Policy=uint64(Policy);
%     Policy=double(Policy);
elseif vfoptions.policy_forceintegertype==2
    % Do the actual rounding to integers
    Policy=round(Policy);
end

end