package com.cikulche.domain.user.service;

import com.cikulche.domain.user.dto.AuthResponse;
import com.cikulche.domain.user.dto.LoginRequest;
import com.cikulche.domain.user.dto.RegisterRequest;
import com.cikulche.domain.user.model.User;
import com.cikulche.domain.user.repository.UserRepository;
import com.cikulche.infrastructure.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthenticationService {

    private final UserRepository repository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

    public AuthResponse register(RegisterRequest request) {
        var user = User.builder()
                .name(request.getName())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword())) // Хешираме!
                .birthYear(request.getBirthYear())
                .averageCycleLength(28) // Default
                .build();

        repository.save(user);

        var jwtToken = jwtService.generateToken(user);
        return AuthResponse.builder()
                .token(jwtToken)
                .name(user.getName())
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        // Тази магия проверява паролата автоматично
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getEmail(),
                        request.getPassword()
                )
        );

        // Ако стигнем до тук, значи паролата е вярна
        var user = repository.findByEmail(request.getEmail())
                .orElseThrow();

        var jwtToken = jwtService.generateToken(user);
        return AuthResponse.builder()
                .token(jwtToken)
                .name(user.getName())
                .build();
    }
}